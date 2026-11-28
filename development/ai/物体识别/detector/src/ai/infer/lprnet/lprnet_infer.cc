#include "ai/infer/lprnet/lprnet_infer.h"
#include "ai/infer/lprnet/postprocess.h"
#include "ai/infer/lprnet/const.h"
#include "hardware/rknn_model_loader.h"
#include "image_utils.h"
#include "im2d.h"
#include "RgaApi.h"
#include "hardware/vpu_decoder.h"
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <unistd.h>
#include <algorithm>

static std::mutex s_lprnet_shared_mutex;
static std::mutex s_lprnet_core_mutexes[4];

LprNetInfer::LprNetInfer(const std::string& model_id, const std::string& model_path)
    : _model_id(model_id),
      _model_path(model_path),
      _is_initialized(false),
      _is_shared_ctx(false),
      _core_mask(0),
      _input_buf(nullptr),
      _input_buf_size(0) {
    memset(&_app_ctx, 0, sizeof(rknn_app_context_t));
}

LprNetInfer::~LprNetInfer() {
    release();
}

std::string LprNetInfer::find_model_path(const std::string& user_path) {
    std::string path_to_try = !user_path.empty() ? user_path : _model_path;
    return RknnModelLoader::instance().find_model_path(path_to_try, _model_id);
}

void LprNetInfer::load_default_labels() {
    const char* const* list = RknnModelLoader::instance().get_labels_list(_model_id);
    if (list) {
        auto new_labels = std::make_shared<std::vector<std::string>>();
        for (int i = 0; list[i] != nullptr; ++i) {
            new_labels->emplace_back(list[i]);
        }
        if (!new_labels->empty()) {
            _labels = new_labels;
        }
    }
}

int LprNetInfer::model_width() const {
    return _app_ctx.model_width > 0 ? _app_ctx.model_width : LPRNET_INPUT_WIDTH;
}

int LprNetInfer::model_height() const {
    return _app_ctx.model_height > 0 ? _app_ctx.model_height : LPRNET_INPUT_HEIGHT;
}

int LprNetInfer::model_channel() const {
    return _app_ctx.model_channel > 0 ? _app_ctx.model_channel : LPRNET_INPUT_CHANNEL;
}

const char* LprNetInfer::get_label_name(int cls_id) {
    if (_labels && cls_id >= 0 && cls_id < (int)_labels->size()) {
        return (*_labels)[cls_id].c_str();
    }
    return nullptr;
}

const std::vector<std::string>& LprNetInfer::get_labels() const {
    static const std::vector<std::string> empty_labels;
    return _labels ? *_labels : empty_labels;
}

bool LprNetInfer::allocate_buffers() {
    free_buffers();

    int w = model_width();
    int h = model_height();
    int c = model_channel();

    size_t raw_size = (size_t)w * h * c;
    _input_buf_size = ((raw_size + 4095) / 4096) * 4096 + 4096;
    _input_buf = nullptr;
    if (posix_memalign(&_input_buf, 4096, _input_buf_size) != 0 || !_input_buf) {
        _input_buf = malloc(_input_buf_size);
    }
    if (!_input_buf) {
        return false;
    }
    memset(_input_buf, 0, _input_buf_size);

    if (_app_ctx.io_num.n_output > 0) {
        _prealloc_outputs.resize(_app_ctx.io_num.n_output);
        _output_buffers.resize(_app_ctx.io_num.n_output);
        memset(_prealloc_outputs.data(), 0, sizeof(rknn_output) * _app_ctx.io_num.n_output);

        for (uint32_t i = 0; i < _app_ctx.io_num.n_output; i++) {
            uint32_t n_elems = _app_ctx.output_attrs ? _app_ctx.output_attrs[i].n_elems : 0;
            if (n_elems == 0) {
                n_elems = LPRNET_OUT_ROWS * LPRNET_OUT_COLS;
            }
            size_t sz = (size_t)n_elems * sizeof(float);
            _output_buffers[i].resize(sz);
            _prealloc_outputs[i].want_float = 1;
            _prealloc_outputs[i].is_prealloc = 1;
            _prealloc_outputs[i].index = i;
            _prealloc_outputs[i].buf = _output_buffers[i].data();
            _prealloc_outputs[i].size = (uint32_t)sz;
        }
    }
    return true;
}

void LprNetInfer::free_buffers() {
    if (_input_buf) {
        free(_input_buf);
        _input_buf = nullptr;
        _input_buf_size = 0;
    }
    _output_buffers.clear();
    _output_buffers.shrink_to_fit();
    _prealloc_outputs.clear();
    _prealloc_outputs.shrink_to_fit();
}

bool LprNetInfer::init(const std::string& model_path, const std::string& label_path) {
    (void)label_path;
    std::lock_guard<std::recursive_mutex> lock(_mutex);
    if (_is_initialized) {
        return true;
    }

    std::string mp = !_model_path.empty() ? _model_path : model_path;
    _model_path = find_model_path(mp);

    if (_model_path.empty() || access(_model_path.c_str(), R_OK) != 0) {
        fprintf(stderr, "[%s] LPRNet 模型加载失败: 找不到模型文件或不可读取 (path=%s)\n",
                _model_id.c_str(), _model_path.empty() ? mp.c_str() : _model_path.c_str());
        return false;
    }

    load_default_labels();
    if (!_labels || _labels->empty() || _labels->size() < LPRNET_OUT_ROWS) {
        fprintf(stderr, "[%s] LPRNet 模型加载失败: 未能从内置库中获取该模型的有效字符表 (size=%zu)\n",
                _model_id.c_str(), _labels ? _labels->size() : 0);
        return false;
    }

    int ret = RknnModelLoader::instance().init_model(_model_path, &_app_ctx, "lprnet", "lprnet");
    if (ret < 0) {
        fprintf(stderr, "[%s] LPRNet 模型加载失败: 解密或 RKNN 初始化失败 (ret=%d, path=%s)\n",
                _model_id.c_str(), ret, _model_path.c_str());
        return false;
    }

    _ctx_mutex = std::make_shared<std::mutex>();

    if (!allocate_buffers()) {
        fprintf(stderr, "[%s] LPRNet 模型加载失败: 缓冲区分配失败\n", _model_id.c_str());
        release();
        return false;
    }

    _is_initialized = true;
    printf("[%s] LPRNet 字符识别模型加载成功: %s (chars=%zu)\n",
           _model_id.c_str(), _model_path.c_str(), _labels->size());
    fflush(stdout);
    return true;
}

void LprNetInfer::release() {
    std::lock_guard<std::recursive_mutex> lock(_mutex);
    if (!_is_initialized && _app_ctx.rknn_ctx == 0) {
        return;
    }

    free_buffers();

    if (!_is_shared_ctx && _app_ctx.rknn_ctx != 0) {
        rknn_destroy(_app_ctx.rknn_ctx);
    }
    _app_ctx.rknn_ctx = 0;

    if (_app_ctx.input_attrs) {
        free(_app_ctx.input_attrs);
        _app_ctx.input_attrs = nullptr;
    }
    if (_app_ctx.output_attrs) {
        free(_app_ctx.output_attrs);
        _app_ctx.output_attrs = nullptr;
    }

    _is_initialized = false;
    _is_shared_ctx = false;
    _master_model.reset();
}

std::string LprNetInfer::recognize_plate(image_buffer_t& plate_img) {
    std::lock_guard<std::recursive_mutex> lock(_mutex);
    if (!_is_initialized || _app_ctx.rknn_ctx == 0 || !_input_buf || !_labels) {
        return "";
    }

    int target_w = model_width();
    int target_h = model_height();
    int target_c = model_channel();
    size_t target_size = (size_t)target_w * target_h * target_c;

    if (plate_img.virt_addr == _input_buf && plate_img.width == target_w && plate_img.height == target_h) {
    } else if (plate_img.virt_addr != nullptr) {
        image_buffer_t dst_img;
        memset(&dst_img, 0, sizeof(image_buffer_t));
        dst_img.width = target_w;
        dst_img.height = target_h;
        dst_img.width_stride = target_w;
        dst_img.height_stride = target_h;
        dst_img.format = IMAGE_FORMAT_RGB888;
        dst_img.virt_addr = (unsigned char*)_input_buf;
        dst_img.size = (int)target_size;
        dst_img.fd = -1;

        image_rect_t src_box = {0, 0, plate_img.width, plate_img.height};
        image_rect_t dst_box = {0, 0, target_w, target_h};
        int ret = convert_image(&plate_img, &dst_img, &src_box, &dst_box, 0);
        if (ret < 0) {
            return "";
        }
    } else {
        return "";
    }

    std::unique_lock<std::mutex> core_lock;
    if (_core_mask == RKNN_NPU_CORE_0) {
        core_lock = std::unique_lock<std::mutex>(s_lprnet_core_mutexes[1]);
    } else if (_core_mask == RKNN_NPU_CORE_1) {
        core_lock = std::unique_lock<std::mutex>(s_lprnet_core_mutexes[2]);
    } else if (_core_mask == RKNN_NPU_CORE_2) {
        core_lock = std::unique_lock<std::mutex>(s_lprnet_core_mutexes[3]);
    } else {
        core_lock = std::unique_lock<std::mutex>(s_lprnet_core_mutexes[0]);
    }

    std::unique_lock<std::mutex> ctx_lock;
    if (_ctx_mutex) {
        ctx_lock = std::unique_lock<std::mutex>(*_ctx_mutex);
    }

    rknn_input inputs[1];
    memset(inputs, 0, sizeof(inputs));
    inputs[0].index = 0;
    inputs[0].type = RKNN_TENSOR_UINT8;
    inputs[0].fmt = RKNN_TENSOR_NHWC;
    inputs[0].size = (uint32_t)target_size;
    inputs[0].buf = _input_buf;

    int ret = rknn_inputs_set(_app_ctx.rknn_ctx, 1, inputs);
    if (ret < 0) {
        return "";
    }

    ret = rknn_run(_app_ctx.rknn_ctx, nullptr);
    if (ret < 0) {
        return "";
    }

    std::string plate_text;
    if (!_prealloc_outputs.empty()) {
        _prealloc_outputs[0].want_float = 1;
        _prealloc_outputs[0].is_prealloc = 1;
        _prealloc_outputs[0].index = 0;
        _prealloc_outputs[0].buf = _output_buffers[0].data();
        _prealloc_outputs[0].size = (uint32_t)_output_buffers[0].size();

        ret = rknn_outputs_get(_app_ctx.rknn_ctx, 1, _prealloc_outputs.data(), nullptr);
        if (ret >= 0) {
            plate_text = lprnet::decode_ctc((const float*)_prealloc_outputs[0].buf, *_labels);
            rknn_outputs_release(_app_ctx.rknn_ctx, 1, _prealloc_outputs.data());
        }
    } else {
        rknn_output outputs[1];
        memset(outputs, 0, sizeof(outputs));
        outputs[0].index = 0;
        outputs[0].want_float = 1;

        ret = rknn_outputs_get(_app_ctx.rknn_ctx, 1, outputs, nullptr);
        if (ret >= 0) {
            plate_text = lprnet::decode_ctc((const float*)outputs[0].buf, *_labels);
            rknn_outputs_release(_app_ctx.rknn_ctx, 1, outputs);
        }
    }

    return plate_text;
}

bool LprNetInfer::infer(image_buffer_t& img, DetectResult& result) {
    std::string plate = recognize_plate(img);
    if (plate.empty()) {
        return false;
    }

    YoloDetectObject obj;
    obj.model_id = _model_id;
    obj.class_id = 0;
    obj.label = "license_plate";
    obj.text = plate;
    obj.score = 0.99f;
    obj.box[0] = 0;
    obj.box[1] = 0;
    obj.box[2] = img.width;
    obj.box[3] = img.height;
    obj.rel_box[0] = 0.0f;
    obj.rel_box[1] = 0.0f;
    obj.rel_box[2] = 1.0f;
    obj.rel_box[3] = 1.0f;

    result.objects.push_back(obj);
    return true;
}

bool LprNetInfer::infer_frame(const std::shared_ptr<VpuDecoder::FrameBuffer>& frame, DetectResult& result) {
    if (!frame || (frame->dma_fd < 0 && frame->data.empty()) || !_is_initialized || !_input_buf) {
        return false;
    }

    int orig_w = frame->width;
    int orig_h = frame->height;
    if (orig_w <= 0 || orig_h <= 0) {
        return false;
    }

    int target_w = model_width();
    int target_h = model_height();
    unsigned char* dst_rgb = static_cast<unsigned char*>(_input_buf);

    int src_hor_stride = std::max(frame->hor_stride, orig_w);
    int src_ver_stride = std::max(frame->ver_stride, orig_h);

    bool rga_ok = false;
#if !defined(DISABLE_RGA)
    if (frame->dma_fd >= 0) {
        rga_buffer_t rga_src = wrapbuffer_fd(frame->dma_fd, orig_w, orig_h, RK_FORMAT_YCbCr_420_SP, src_hor_stride, src_ver_stride);
        rga_buffer_t rga_dst = wrapbuffer_virtualaddr(dst_rgb, target_w, target_h, RK_FORMAT_RGB_888, target_w, target_h);
        im_rect srect = {0, 0, (orig_w / 2) * 2, (orig_h / 2) * 2};
        im_rect drect = {0, 0, target_w, target_h};
        rga_buffer_t pat;
        memset(&pat, 0, sizeof(rga_buffer_t));
        im_rect prect = {0, 0, 0, 0};
        std::lock_guard<std::mutex> rga_lock(get_global_rga_mutex());
        if (imcheck(rga_src, rga_dst, srect, drect) == IM_STATUS_NOERROR) {
            int ret_rga = improcess(rga_src, rga_dst, pat, srect, drect, prect, 0);
            if (ret_rga == IM_STATUS_SUCCESS || ret_rga > 0) {
                rga_ok = true;
            }
        }
    }
#endif

    if (!rga_ok) {
        return false;
    }

    image_buffer_t img;
    memset(&img, 0, sizeof(image_buffer_t));
    img.width = target_w;
    img.height = target_h;
    img.format = IMAGE_FORMAT_RGB888;
    img.virt_addr = dst_rgb;
    img.size = (size_t)target_w * target_h * 3;

    result.orig_width = orig_w;
    result.orig_height = orig_h;
    return infer(img, result);
}

std::shared_ptr<IModelInfer> LprNetInfer::clone(uint32_t core_mask) {
    std::lock_guard<std::recursive_mutex> lock(_mutex);
    if (!_is_initialized || _app_ctx.rknn_ctx == 0 ||
        !_app_ctx.input_attrs || !_app_ctx.output_attrs ||
        _app_ctx.io_num.n_input == 0 || _app_ctx.io_num.n_output == 0) {
        return nullptr;
    }

    auto cloned = std::make_shared<LprNetInfer>(_model_id, _model_path);
    cloned->_master_model = _master_model ? _master_model : shared_from_this();
    cloned->_labels = _labels;
    cloned->_model_path = _model_path;
    cloned->_core_mask = core_mask;

    int ret = -1;
    rknn_context dup_ctx = 0;
    int dup_ret = rknn_dup_context(&_app_ctx.rknn_ctx, &dup_ctx);
    if (dup_ret != RKNN_SUCC) {
        return nullptr;
    }

    cloned->_app_ctx.rknn_ctx = dup_ctx;
    cloned->_app_ctx.is_quant = _app_ctx.is_quant;
    cloned->_app_ctx.io_num = _app_ctx.io_num;
    cloned->_app_ctx.model_channel = _app_ctx.model_channel;
    cloned->_app_ctx.model_width = _app_ctx.model_width;
    cloned->_app_ctx.model_height = _app_ctx.model_height;

    cloned->_app_ctx.input_attrs = (rknn_tensor_attr*)malloc(_app_ctx.io_num.n_input * sizeof(rknn_tensor_attr));
    cloned->_app_ctx.output_attrs = (rknn_tensor_attr*)malloc(_app_ctx.io_num.n_output * sizeof(rknn_tensor_attr));
    if (!cloned->_app_ctx.input_attrs || !cloned->_app_ctx.output_attrs) {
        if (cloned->_app_ctx.input_attrs) {
            free(cloned->_app_ctx.input_attrs);
            cloned->_app_ctx.input_attrs = nullptr;
        }
        if (cloned->_app_ctx.output_attrs) {
            free(cloned->_app_ctx.output_attrs);
            cloned->_app_ctx.output_attrs = nullptr;
        }
        rknn_destroy(dup_ctx);
        cloned->_app_ctx.rknn_ctx = 0;
        return nullptr;
    }
    memcpy(cloned->_app_ctx.input_attrs, _app_ctx.input_attrs, _app_ctx.io_num.n_input * sizeof(rknn_tensor_attr));
    memcpy(cloned->_app_ctx.output_attrs, _app_ctx.output_attrs, _app_ctx.io_num.n_output * sizeof(rknn_tensor_attr));
    cloned->_ctx_mutex = std::make_shared<std::mutex>();
    cloned->_is_shared_ctx = false;
    ret = 0;

    if (ret < 0) {
        return nullptr;
    }

    if (!cloned->_is_shared_ctx && core_mask != RKNN_NPU_CORE_AUTO) {
        int ret_mask = rknn_set_core_mask(cloned->_app_ctx.rknn_ctx, (rknn_core_mask)core_mask);
        if (ret_mask < 0) {
            cloned->_core_mask = RKNN_NPU_CORE_AUTO;
        }
    }

    if (!cloned->allocate_buffers()) {
        cloned->release();
        return nullptr;
    }

    cloned->_is_initialized = true;
    return cloned;
}
