#include "ai/yolo11/yolo11_infer.h"
#include "security/model_decrypter.h"
#include "utils/path_utils.h"
#include "ai/yolo11/const.h"
#include "image_utils.h"
#include "ai/yolo11/postprocess.h"
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <fstream>
#include <unistd.h>
#include <algorithm>

static std::mutex s_yolo11_shared_mutex;
static std::mutex s_yolo11_core_mutexes[4];

Yolo11Infer::Yolo11Infer(const std::string& model_name,
                         const std::string& model_path,
                         const std::string& label_path,
                         float conf_thresh,
                         float nms_thresh)
    : _model_name(model_name),
      _model_path(model_path),
      _label_path(label_path),
      _conf_thresh(conf_thresh > 0.0f ? conf_thresh : BOX_THRESH),
      _nms_thresh(nms_thresh > 0.0f ? nms_thresh : NMS_THRESH),
      _is_initialized(false),
      _is_shared_ctx(false),
      _postprocess_inited(false),
      _core_mask(0),
      _input_buf(nullptr),
      _input_buf_size(0),
      _has_prealloc_outputs(false) {
    memset(&_app_ctx, 0, sizeof(rknn_app_context_t));
}

Yolo11Infer::~Yolo11Infer() {
    release();
}

std::string Yolo11Infer::find_model_path(const std::string& user_path) {
    std::string path_to_try = !user_path.empty() ? user_path : _model_path;
    return ModelDecrypter::instance().find_model_path(path_to_try, _model_name);
}

std::string Yolo11Infer::find_labels_path(const std::string& user_path) {
    if (!user_path.empty()) {
        std::string r = PathUtils::resolve_path(user_path);
        if (!r.empty()) return r;
        return user_path;
    }
    return "";
}

void Yolo11Infer::load_labels(const std::string& path) {
    std::string resolved = find_labels_path(path);
    if (resolved.empty()) {
        return;
    }

    std::ifstream file(resolved);
    if (!file.is_open()) {
        return;
    }

    auto new_labels = std::make_shared<std::vector<std::string>>();
    std::string line;
    while (std::getline(file, line)) {
        while (!line.empty() && (line.back() == '\r' || line.back() == '\n' || line.back() == ' ')) {
            line.pop_back();
        }
        if (!line.empty()) {
            new_labels->push_back(line);
        }
    }
    if (!new_labels->empty()) {
        _labels = new_labels;
    }
}

void Yolo11Infer::load_default_labels() {
    const char* const* list = ModelDecrypter::instance().get_labels_list(_model_name);
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

bool Yolo11Infer::allocate_buffers() {
    free_buffers();

    if (_app_ctx.model_width <= 0 || _app_ctx.model_height <= 0 || _app_ctx.model_channel <= 0) {
        return false;
    }

    size_t raw_size = (size_t)_app_ctx.model_width * _app_ctx.model_height * _app_ctx.model_channel;
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
        if (!_app_ctx.output_attrs) {
            return false;
        }
        _prealloc_outputs.resize(_app_ctx.io_num.n_output);
        _output_buffers.resize(_app_ctx.io_num.n_output);
        memset(_prealloc_outputs.data(), 0, sizeof(rknn_output) * _app_ctx.io_num.n_output);

        for (uint32_t i = 0; i < _app_ctx.io_num.n_output; i++) {
            bool want_float = (!_app_ctx.is_quant);
            size_t sz = 0;
            uint32_t n_elems = _app_ctx.output_attrs[i].n_elems;
            if (n_elems == 0 && _app_ctx.output_attrs[i].n_dims > 0) {
                n_elems = 1;
                for (uint32_t d = 0; d < _app_ctx.output_attrs[i].n_dims; ++d) {
                    if (_app_ctx.output_attrs[i].dims[d] > 0) {
                        n_elems *= _app_ctx.output_attrs[i].dims[d];
                    }
                }
            }
            if (want_float) {
                sz = (size_t)n_elems * sizeof(float);
            } else {
                sz = (size_t)_app_ctx.output_attrs[i].size;
                if (sz < (size_t)n_elems) {
                    sz = (size_t)n_elems;
                }
            }
            if (sz == 0) sz = 65536;
            _output_buffers[i].resize(sz);
            _prealloc_outputs[i].want_float = want_float;
            _prealloc_outputs[i].is_prealloc = 1;
            _prealloc_outputs[i].index = i;
            _prealloc_outputs[i].buf = _output_buffers[i].data();
            _prealloc_outputs[i].size = (uint32_t)sz;
        }
        _has_prealloc_outputs = true;
    }
    return true;
}

void Yolo11Infer::free_buffers() {
    if (_input_buf) {
        free(_input_buf);
        _input_buf = nullptr;
        _input_buf_size = 0;
    }
    _output_buffers.clear();
    _output_buffers.shrink_to_fit();
    _prealloc_outputs.clear();
    _prealloc_outputs.shrink_to_fit();
    _has_prealloc_outputs = false;
}

bool Yolo11Infer::init(const std::string& model_path, const std::string& label_path) {
    std::lock_guard<std::recursive_mutex> lock(_mutex);
    if (_is_initialized) {
        return true;
    }

    std::string mp = !_model_path.empty() ? _model_path : model_path;
    std::string lp = !_label_path.empty() ? _label_path : label_path;

    _model_path = find_model_path(mp);
    _label_path = find_labels_path(lp);

    if (_model_path.empty() || access(_model_path.c_str(), R_OK) != 0) {
        fprintf(stderr, "[%s] 模型加载失败: 找不到模型文件或不可读取 (path=%s)\n",
                _model_name.c_str(), _model_path.empty() ? mp.c_str() : _model_path.c_str());
        return false;
    }

    if (!_postprocess_inited) {
        if (!_label_path.empty()) {
            load_labels(_label_path);
        }
        if (!_labels) {
            load_default_labels();
        }
        _postprocess_inited = true;
    }

    int ret = ModelDecrypter::instance().init_model(_model_path, &_app_ctx, _model_name, _model_name);
    if (ret < 0) {
        fprintf(stderr, "[%s] 模型加载失败: 模型解密或初始化失败 (ret=%d, path=%s)\n",
                _model_name.c_str(), ret, _model_path.c_str());
        return false;
    }

    _ctx_mutex = std::make_shared<std::mutex>();

    if (!allocate_buffers()) {
        fprintf(stderr, "[%s] 模型加载失败: 缓冲区分配失败\n", _model_name.c_str());
        release();
        return false;
    }

    _is_initialized = true;
    printf("[%s] 模型加载成功: %s\n", _model_name.c_str(), _model_path.c_str());
    fflush(stdout);
    return true;
}

std::shared_ptr<IModelInfer> Yolo11Infer::clone(uint32_t core_mask) {
    std::lock_guard<std::recursive_mutex> lock(_mutex);
    if (!_is_initialized || _app_ctx.rknn_ctx == 0 ||
        !_app_ctx.input_attrs || !_app_ctx.output_attrs ||
        _app_ctx.io_num.n_input == 0 || _app_ctx.io_num.n_output == 0) {
        return nullptr;
    }

    auto cloned = std::make_shared<Yolo11Infer>(_model_name, _model_path, _label_path, _conf_thresh, _nms_thresh);
    cloned->_master_model = _master_model ? _master_model : shared_from_this();
    cloned->_labels = _labels;
    cloned->_model_path = _model_path;
    cloned->_label_path = _label_path;
    cloned->_core_mask = core_mask;

    int ret = -1;
    if (_app_ctx.rknn_ctx != 0) {
        rknn_context dup_ctx = 0;
        int dup_ret = rknn_dup_context(&_app_ctx.rknn_ctx, &dup_ctx);
        if (dup_ret == RKNN_SUCC) {
            cloned->_app_ctx.rknn_ctx = dup_ctx;
            cloned->_app_ctx.is_quant = _app_ctx.is_quant;
            cloned->_app_ctx.io_num = _app_ctx.io_num;
            cloned->_app_ctx.model_channel = _app_ctx.model_channel;
            cloned->_app_ctx.model_width = _app_ctx.model_width;
            cloned->_app_ctx.model_height = _app_ctx.model_height;

            cloned->_app_ctx.input_attrs = (rknn_tensor_attr *)malloc(_app_ctx.io_num.n_input * sizeof(rknn_tensor_attr));
            cloned->_app_ctx.output_attrs = (rknn_tensor_attr *)malloc(_app_ctx.io_num.n_output * sizeof(rknn_tensor_attr));
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
        } else {
            cloned->_app_ctx = _app_ctx;
            cloned->_app_ctx.input_attrs = nullptr;
            cloned->_app_ctx.output_attrs = nullptr;
            cloned->_app_ctx.input_attrs = (rknn_tensor_attr *)malloc(_app_ctx.io_num.n_input * sizeof(rknn_tensor_attr));
            cloned->_app_ctx.output_attrs = (rknn_tensor_attr *)malloc(_app_ctx.io_num.n_output * sizeof(rknn_tensor_attr));
            if (!cloned->_app_ctx.input_attrs || !cloned->_app_ctx.output_attrs) {
                if (cloned->_app_ctx.input_attrs) {
                    free(cloned->_app_ctx.input_attrs);
                    cloned->_app_ctx.input_attrs = nullptr;
                }
                if (cloned->_app_ctx.output_attrs) {
                    free(cloned->_app_ctx.output_attrs);
                    cloned->_app_ctx.output_attrs = nullptr;
                }
                cloned->_app_ctx.rknn_ctx = 0;
                return nullptr;
            }
            memcpy(cloned->_app_ctx.input_attrs, _app_ctx.input_attrs, _app_ctx.io_num.n_input * sizeof(rknn_tensor_attr));
            memcpy(cloned->_app_ctx.output_attrs, _app_ctx.output_attrs, _app_ctx.io_num.n_output * sizeof(rknn_tensor_attr));
            cloned->_ctx_mutex = _ctx_mutex;
            cloned->_is_shared_ctx = true;
            ret = 0;
        }
    }

    if (ret < 0) {
        return nullptr;
    }

    if (!cloned->_is_shared_ctx && core_mask != RKNN_NPU_CORE_AUTO) {
        int ret_mask = rknn_set_core_mask(cloned->_app_ctx.rknn_ctx, (rknn_core_mask)core_mask);
        if (ret_mask != RKNN_SUCC) {
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

bool Yolo11Infer::do_infer(const letterbox_t& letter_box, DetectResult& result, int orig_w, int orig_h) {
    std::unique_lock<std::mutex> ctx_lock(*_ctx_mutex);
    std::unique_lock<std::mutex> core_lock;
    std::unique_lock<std::mutex> secondary_lock;
    std::unique_lock<std::mutex> tertiary_lock;
    if (_is_shared_ctx) {
        core_lock = std::unique_lock<std::mutex>(s_yolo11_shared_mutex, std::defer_lock);
        secondary_lock = std::unique_lock<std::mutex>(s_yolo11_core_mutexes[0], std::defer_lock);
        std::lock(core_lock, secondary_lock);
    } else if (_core_mask == RKNN_NPU_CORE_0) {
        core_lock = std::unique_lock<std::mutex>(s_yolo11_core_mutexes[0]);
    } else if (_core_mask == RKNN_NPU_CORE_1) {
        core_lock = std::unique_lock<std::mutex>(s_yolo11_core_mutexes[1]);
    } else if (_core_mask == RKNN_NPU_CORE_2) {
        core_lock = std::unique_lock<std::mutex>(s_yolo11_core_mutexes[2]);
    } else if (_core_mask == RKNN_NPU_CORE_0_1) {
        core_lock = std::unique_lock<std::mutex>(s_yolo11_core_mutexes[0], std::defer_lock);
        secondary_lock = std::unique_lock<std::mutex>(s_yolo11_core_mutexes[1], std::defer_lock);
        std::lock(core_lock, secondary_lock);
    } else if (_core_mask == RKNN_NPU_CORE_0_1_2) {
        core_lock = std::unique_lock<std::mutex>(s_yolo11_core_mutexes[0], std::defer_lock);
        secondary_lock = std::unique_lock<std::mutex>(s_yolo11_core_mutexes[1], std::defer_lock);
        tertiary_lock = std::unique_lock<std::mutex>(s_yolo11_core_mutexes[2], std::defer_lock);
        std::lock(core_lock, secondary_lock, tertiary_lock);
    } else {
        core_lock = std::unique_lock<std::mutex>(s_yolo11_core_mutexes[0]);
    }

    if (orig_w > 0 && result.orig_width <= 0) result.orig_width = orig_w;
    if (orig_h > 0 && result.orig_height <= 0) result.orig_height = orig_h;

    if (_app_ctx.io_num.n_input != 1 || _app_ctx.io_num.n_output < 6) {
        return false;
    }

    std::vector<rknn_input> inputs(_app_ctx.io_num.n_input);
    memset(inputs.data(), 0, sizeof(rknn_input) * inputs.size());
    inputs[0].index = 0;
    inputs[0].type = RKNN_TENSOR_UINT8;
    inputs[0].fmt = RKNN_TENSOR_NHWC;
    inputs[0].size = _app_ctx.model_width * _app_ctx.model_height * _app_ctx.model_channel;
    inputs[0].buf = _input_buf;

    int ret = rknn_inputs_set(_app_ctx.rknn_ctx, _app_ctx.io_num.n_input, inputs.data());
    if (ret < 0) {
        return false;
    }

    ret = rknn_run(_app_ctx.rknn_ctx, nullptr);
    if (ret < 0) {
        return false;
    }

    object_detect_result_list od_results;
    memset(&od_results, 0, sizeof(od_results));

    if (_has_prealloc_outputs) {
        for (uint32_t i = 0; i < _app_ctx.io_num.n_output; i++) {
            _prealloc_outputs[i].want_float = (!_app_ctx.is_quant);
            _prealloc_outputs[i].is_prealloc = 1;
            _prealloc_outputs[i].index = i;
            _prealloc_outputs[i].buf = _output_buffers[i].data();
            _prealloc_outputs[i].size = (uint32_t)_output_buffers[i].size();
        }
        ret = rknn_outputs_get(_app_ctx.rknn_ctx, _app_ctx.io_num.n_output, _prealloc_outputs.data(), NULL);
        if (ret < 0) {
            return false;
        }
        post_process(&_app_ctx, _prealloc_outputs.data(), const_cast<letterbox_t*>(&letter_box), _conf_thresh, _nms_thresh, &od_results);
        rknn_outputs_release(_app_ctx.rknn_ctx, _app_ctx.io_num.n_output, _prealloc_outputs.data());
    } else {
        std::vector<rknn_output> outputs(_app_ctx.io_num.n_output);
        memset(outputs.data(), 0, sizeof(rknn_output) * outputs.size());
        for (uint32_t i = 0; i < _app_ctx.io_num.n_output; i++) {
            outputs[i].index = i;
            outputs[i].want_float = (!_app_ctx.is_quant);
        }
        ret = rknn_outputs_get(_app_ctx.rknn_ctx, _app_ctx.io_num.n_output, outputs.data(), NULL);
        if (ret < 0) {
            return false;
        }
        post_process(&_app_ctx, outputs.data(), const_cast<letterbox_t*>(&letter_box), _conf_thresh, _nms_thresh, &od_results);
        rknn_outputs_release(_app_ctx.rknn_ctx, _app_ctx.io_num.n_output, outputs.data());
    }

    int valid_det_count = od_results.count;
    if (valid_det_count < 0) valid_det_count = 0;
    if (valid_det_count > OBJ_NUMB_MAX_SIZE) valid_det_count = OBJ_NUMB_MAX_SIZE;

    result.objects.reserve(result.objects.size() + valid_det_count);
    int rw = (orig_w > 0) ? orig_w : result.orig_width;
    int rh = (orig_h > 0) ? orig_h : result.orig_height;

    for (int i = 0; i < valid_det_count; ++i) {
        YoloDetectObject obj;
        obj.model_name = _model_name;
        obj.class_id = od_results.results[i].cls_id;
        const char* lbl = get_label_name(obj.class_id);
        obj.label = (lbl ? lbl : "object");
        obj.score = od_results.results[i].prop;
        obj.box[0] = od_results.results[i].box.left;
        obj.box[1] = od_results.results[i].box.top;
        obj.box[2] = od_results.results[i].box.right;
        obj.box[3] = od_results.results[i].box.bottom;

        if (rw > 0) {
            if (obj.box[0] < 0) obj.box[0] = 0;
            if (obj.box[0] > rw) obj.box[0] = rw;
            if (obj.box[2] < 0) obj.box[2] = 0;
            if (obj.box[2] > rw) obj.box[2] = rw;
        }
        if (rh > 0) {
            if (obj.box[1] < 0) obj.box[1] = 0;
            if (obj.box[1] > rh) obj.box[1] = rh;
            if (obj.box[3] < 0) obj.box[3] = 0;
            if (obj.box[3] > rh) obj.box[3] = rh;
        }

        float rx1 = (rw > 0) ? ((float)obj.box[0] / (float)rw) : 0.0f;
        float ry1 = (rh > 0) ? ((float)obj.box[1] / (float)rh) : 0.0f;
        float rx2 = (rw > 0) ? ((float)obj.box[2] / (float)rw) : 0.0f;
        float ry2 = (rh > 0) ? ((float)obj.box[3] / (float)rh) : 0.0f;

        if (rx1 < 0.0f) rx1 = 0.0f; else if (rx1 > 1.0f) rx1 = 1.0f;
        if (ry1 < 0.0f) ry1 = 0.0f; else if (ry1 > 1.0f) ry1 = 1.0f;
        if (rx2 < 0.0f) rx2 = 0.0f; else if (rx2 > 1.0f) rx2 = 1.0f;
        if (ry2 < 0.0f) ry2 = 0.0f; else if (ry2 > 1.0f) ry2 = 1.0f;

        obj.rel_box[0] = rx1;
        obj.rel_box[1] = ry1;
        obj.rel_box[2] = rx2;
        obj.rel_box[3] = ry2;

        result.objects.push_back(obj);
    }

    return true;
}

bool Yolo11Infer::infer_frame(const std::shared_ptr<VpuDecoder::FrameBuffer>& frame, DetectResult& result) {
    std::lock_guard<std::recursive_mutex> lock(_mutex);
    if (!_is_initialized || !frame || frame->data.empty() || !_input_buf || _app_ctx.rknn_ctx == 0) {
        return false;
    }

    image_buffer_t dst_img;
    memset(&dst_img, 0, sizeof(image_buffer_t));
    dst_img.width = _app_ctx.model_width;
    dst_img.height = _app_ctx.model_height;
    dst_img.width_stride = _app_ctx.model_width;
    dst_img.height_stride = _app_ctx.model_height;
    dst_img.format = IMAGE_FORMAT_RGB888;
    dst_img.virt_addr = (unsigned char*)_input_buf;
    dst_img.size = (int)(_app_ctx.model_width * _app_ctx.model_height * _app_ctx.model_channel);
    dst_img.fd = -1;

    letterbox_t letter_box;
    memset(&letter_box, 0, sizeof(letterbox_t));
    int orig_w = 0, orig_h = 0;

    if (!VpuDecoder::letterbox_frame(frame, &dst_img, &letter_box, &orig_w, &orig_h)) {
        return false;
    }

    return do_infer(letter_box, result, orig_w, orig_h);
}

bool Yolo11Infer::infer(image_buffer_t& img, DetectResult& result) {
    std::lock_guard<std::recursive_mutex> lock(_mutex);
    if (!_is_initialized || !img.virt_addr || !_input_buf || _app_ctx.rknn_ctx == 0) {
        return false;
    }

    int orig_w = result.orig_width > 0 ? result.orig_width : img.width;
    int orig_h = result.orig_height > 0 ? result.orig_height : img.height;
    if (orig_w <= 0 || orig_h <= 0) {
        return false;
    }

    letterbox_t letter_box;
    memset(&letter_box, 0, sizeof(letterbox_t));

    if (img.virt_addr == _input_buf && img.width == _app_ctx.model_width && img.height == _app_ctx.model_height) {
        float scale = std::min((float)_app_ctx.model_width / orig_w, (float)_app_ctx.model_height / orig_h);
        letter_box.scale = scale;
        letter_box.x_pad = (_app_ctx.model_width - (int)(orig_w * scale)) / 2;
        letter_box.y_pad = (_app_ctx.model_height - (int)(orig_h * scale)) / 2;
    } else {
        image_buffer_t dst_img;
        memset(&dst_img, 0, sizeof(image_buffer_t));
        dst_img.width = _app_ctx.model_width;
        dst_img.height = _app_ctx.model_height;
        dst_img.width_stride = _app_ctx.model_width;
        dst_img.height_stride = _app_ctx.model_height;
        dst_img.format = IMAGE_FORMAT_RGB888;
        dst_img.virt_addr = (unsigned char*)_input_buf;
        dst_img.size = (int)(_app_ctx.model_width * _app_ctx.model_height * _app_ctx.model_channel);
        dst_img.fd = -1;

        int r = convert_image_with_letterbox(&img, &dst_img, &letter_box, 114);
        if (r < 0) {
            return false;
        }
    }

    return do_infer(letter_box, result, orig_w, orig_h);
}

void Yolo11Infer::release() {
    std::lock_guard<std::recursive_mutex> lock(_mutex);
    free_buffers();

    if (_app_ctx.input_attrs) {
        free(_app_ctx.input_attrs);
        _app_ctx.input_attrs = nullptr;
    }
    if (_app_ctx.output_attrs) {
        free(_app_ctx.output_attrs);
        _app_ctx.output_attrs = nullptr;
    }
    if (!_is_shared_ctx && _app_ctx.rknn_ctx != 0) {
        rknn_destroy(_app_ctx.rknn_ctx);
    }
    _ctx_mutex.reset();
    memset(&_app_ctx, 0, sizeof(rknn_app_context_t));
    _is_shared_ctx = false;

    if (_master_model) {
        _master_model.reset();
    } else {
        if (_labels) {
            _labels.reset();
        }
        _postprocess_inited = false;
    }

    _is_initialized = false;
}

static const std::vector<std::string> s_empty_labels;

const std::vector<std::string>& Yolo11Infer::get_labels() const {
    if (_labels) {
        return *_labels;
    }
    return s_empty_labels;
}

const char* Yolo11Infer::get_label_name(int cls_id) {
    if (_labels && cls_id >= 0 && cls_id < (int)_labels->size()) {
        return (*_labels)[cls_id].c_str();
    }
    return "object";
}
