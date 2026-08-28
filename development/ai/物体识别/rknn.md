# rknn

## 说明

[mpp](https://github.com/rockchip-linux/mpp/)
[zoo](https://github.com/airockchip/rknn_model_zoo/)

基于硬件实现检测，暴露方法给 rust

## 结构

```sh
├── 3rdparty
│   ├── mpp
│   │   └── inc
│   └── rknn_model_zoo
│       ├── 3rdparty
│       │   ├── librga
│       │   ├── rknpu2
│       │   └── stb_image
│       ├── examples
│       │   └── yolov8
│       │       ├── cpp
│       │       │   └── rknpu2
│       │       └── model
│       └── utils
├── include
│   └── hardware
└── src
    └── hardware
```

## 代码

复制

```sh
mpp/inc/* 复制到 3rdparty/mpp/inc/
```

```sh
rknn_model_zoo/3rdparty/ 下 librga rknpu2 stb_image
复制到
3rdparty/rknn_model_zoo/3rdparty/
```

```sh
rknn_model_zoo/examples/yolov8/ 下 cpp model
复制到
3rdparty/rknn_model_zoo/examples/yolov8/
```

```sh
rknn_model_zoo/utils/*
复制到
3rdparty/rknn_model_zoo/utils/
```

include/hardware/channel_decoder.h

```c
#pragma once

#include "hardware/vpu_decoder.h"
#include <map>
#include <memory>
#include <mutex>

class ChannelDecoder {
public:
    static ChannelDecoder& shareInstance();

    VpuDecoder* get_or_create(int ch);

private:
    ChannelDecoder() = default;
    std::mutex _map_mutex;
    std::map<int, std::unique_ptr<VpuDecoder>> _decoders;
};
```

src/hardware/channel_decoder.cc

```c
#include "hardware/channel_decoder.h"
#include <cstdio>

ChannelDecoder& ChannelDecoder::shareInstance() {
    static ChannelDecoder s_instance;
    return s_instance;
}

VpuDecoder* ChannelDecoder::get_or_create(int ch) {
    std::lock_guard<std::mutex> lock(_map_mutex);
    auto it = _decoders.find(ch);
    if (it != _decoders.end()) {
        return it->second.get();
    }
    auto decoder = std::make_unique<VpuDecoder>();
    VpuDecoder* ptr = decoder.get();
    _decoders[ch] = std::move(decoder);
    printf("[detect_lib] 已为通道 %d 初始化独立的 vpu h.264 解码器\n", ch);
    return ptr;
}
```

include/hardware/npu_infer.h

```c
#pragma once

#include "image_utils.h"
#include "yolov8.h"
#include "postprocess.h"
#include "hardware/vpu_decoder.h"
#include <string>
#include <vector>
#include <mutex>
#include <memory>

class NpuInfer {
public:
    static NpuInfer& shareInstance();

    NpuInfer();
    ~NpuInfer();

    bool init(const std::string& model_path = "", const std::string& label_path = "");
    bool infer(image_buffer_t& img, object_detect_result_list& results);
    int detect_frame(VpuDecoder* decoder, int ch, char* out_buf, int out_buf_size, unsigned long long* out_frame_idx, long long* out_pts_ms);
    const char* get_label_name(int cls_id);
    void release();

private:
    bool infer_internal(image_buffer_t& img, object_detect_result_list& results);
    std::string find_model_path(const std::string& user_path);
    std::string find_labels_path(const std::string& user_path);
    void load_labels(const std::string& path);
    void ensure_nv12_buffer_size(size_t needed_size);

    std::mutex _infer_mutex;
    rknn_app_context_t _app_ctx;
    bool _is_initialized;
    std::vector<std::string> _labels;

    void* _input_buf;
    size_t _input_buf_size;

    void* _nv12_buf;
    size_t _nv12_buf_size;
};
```

src/hardware/npu_infer.cc

```c
#include "hardware/npu_infer.h"
#include "consts.h"
#include "file_utils.h"
#include "image_utils.h"
#include "yolov8.h"
#include "postprocess.h"
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <unistd.h>

NpuInfer& NpuInfer::shareInstance() {
    static NpuInfer s_instance;
    return s_instance;
}

NpuInfer::NpuInfer()
    : _is_initialized(false), _input_buf(nullptr), _input_buf_size(0), _nv12_buf(nullptr), _nv12_buf_size(0) {
    memset(&_app_ctx, 0, sizeof(rknn_app_context_t));
}

NpuInfer::~NpuInfer() {
    release();
}

void NpuInfer::ensure_nv12_buffer_size(size_t needed_size) {
    if (_nv12_buf && _nv12_buf_size >= needed_size) {
        return;
    }
    if (_nv12_buf) {
        free(_nv12_buf);
        _nv12_buf = nullptr;
    }
    size_t alloc_size = ((needed_size + 4095) / 4096) * 4096 + 4096;
    if (alloc_size < 8 * 1024 * 1024) {
        alloc_size = 8 * 1024 * 1024;
    }
    if (posix_memalign(&_nv12_buf, 4096, alloc_size) != 0 || !_nv12_buf) {
        _nv12_buf = malloc(alloc_size);
    }
    _nv12_buf_size = alloc_size;
}

std::string NpuInfer::find_model_path(const std::string& user_path) {
    if (!user_path.empty() && access(user_path.c_str(), R_OK) == 0) {
        return user_path;
    }
    return MODEL_PATH;
}

std::string NpuInfer::find_labels_path(const std::string& user_path) {
    if (!user_path.empty() && access(user_path.c_str(), R_OK) == 0) {
        return user_path;
    }
    return LABEL_PATH;
}

void NpuInfer::load_labels(const std::string& path) {
    _labels.clear();
    std::string resolved = find_labels_path(path);
    if (resolved.empty()) {
        printf("[npu_infer] using built-in labels.\n");
        return;
    }

    std::ifstream file(resolved);
    if (!file.is_open()) {
        printf("[npu_infer] could not open label file %s, using default labels.\n", resolved.c_str());
        return;
    }

    std::string line;
    while (std::getline(file, line)) {
        while (!line.empty() && (line.back() == '\r' || line.back() == '\n' || line.back() == ' ')) {
            line.pop_back();
        }
        if (!line.empty()) {
            _labels.push_back(line);
        }
    }
    printf("[npu_infer] loaded %zu labels from: %s\n", _labels.size(), resolved.c_str());
}

bool NpuInfer::init(const std::string& model_path, const std::string& label_path) {
    std::lock_guard<std::mutex> lock(_infer_mutex);
    if (_is_initialized) {
        return true;
    }

    std::string resolved_model = find_model_path(model_path);
    if (resolved_model.empty()) {
        fprintf(stderr, "[npu_infer] error: model file not found!\n");
        return false;
    }

    printf("[npu_infer] initializing model: %s\n", resolved_model.c_str());
    init_post_process();

    int ret = init_yolov8_model(resolved_model.c_str(), &_app_ctx);
    if (ret < 0) {
        fprintf(stderr, "[npu_infer] error: init model failed (%d)\n", ret);
        return false;
    }

    rknn_set_core_mask(_app_ctx.rknn_ctx, RKNN_NPU_CORE_0_1);

    // Pre-allocate page-aligned (4096-aligned) buffer for hardware RGA & NPU input (zero-churn)
    size_t raw_size = (size_t)_app_ctx.model_width * _app_ctx.model_height * _app_ctx.model_channel;
    _input_buf_size = ((raw_size + 4095) / 4096) * 4096 + 4096;
    _input_buf = nullptr;
    if (posix_memalign(&_input_buf, 4096, _input_buf_size) != 0 || !_input_buf) {
        _input_buf = malloc(_input_buf_size);
    }
    if (_input_buf) {
        memset(_input_buf, 0, _input_buf_size);
    }

    load_labels(label_path);
    _is_initialized = true;
    printf("[npu_infer] npu engine ready. (model: %dx%dx%d, quant: %d, persistent input_buf: %zu bytes)\n",
           _app_ctx.model_width, _app_ctx.model_height, _app_ctx.model_channel, (int)_app_ctx.is_quant, _input_buf_size);
    return true;
}

bool NpuInfer::infer_internal(image_buffer_t& img, object_detect_result_list& results) {
    if (!_is_initialized || !img.virt_addr || !_input_buf) {
        return false;
    }

    memset(&results, 0, sizeof(object_detect_result_list));

    // Prepare target letterbox destination on persistent page-aligned buffer
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

    // Hardware RGA letterbox color conversion (NV12 -> RGB888 letterbox) using pre-allocated page-aligned buffer
    int r = convert_image_with_letterbox(&img, &dst_img, &letter_box, 114);
    if (r < 0) {
        fprintf(stderr, "[npu_infer] convert_image_with_letterbox failed\n");
        return false;
    }

    rknn_input inputs[1];
    memset(inputs, 0, sizeof(inputs));
    inputs[0].index = 0;
    inputs[0].type = RKNN_TENSOR_UINT8;
    inputs[0].fmt = RKNN_TENSOR_NHWC;
    inputs[0].size = _app_ctx.model_width * _app_ctx.model_height * _app_ctx.model_channel;
    inputs[0].buf = _input_buf;

    int ret = rknn_inputs_set(_app_ctx.rknn_ctx, _app_ctx.io_num.n_input, inputs);
    if (ret < 0) {
        fprintf(stderr, "[npu_infer] rknn_inputs_set failed (%d)\n", ret);
        return false;
    }

    ret = rknn_run(_app_ctx.rknn_ctx, nullptr);
    if (ret < 0) {
        fprintf(stderr, "[npu_infer] rknn_run failed (%d)\n", ret);
        return false;
    }

    rknn_output outputs[_app_ctx.io_num.n_output];
    memset(outputs, 0, sizeof(outputs));
    for (int i = 0; i < _app_ctx.io_num.n_output; i++) {
        outputs[i].index = i;
        outputs[i].want_float = (!_app_ctx.is_quant);
    }

    ret = rknn_outputs_get(_app_ctx.rknn_ctx, _app_ctx.io_num.n_output, outputs, NULL);
    if (ret < 0) {
        fprintf(stderr, "[npu_infer] rknn_outputs_get failed (%d)\n", ret);
        return false;
    }

    post_process(&_app_ctx, outputs, &letter_box, BOX_THRESH, NMS_THRESH, &results);

    rknn_outputs_release(_app_ctx.rknn_ctx, _app_ctx.io_num.n_output, outputs);
    return true;
}

bool NpuInfer::infer(image_buffer_t& img, object_detect_result_list& results) {
    std::lock_guard<std::mutex> lock(_infer_mutex);
    if (!_is_initialized) {
        std::string resolved = find_model_path("");
        init_post_process();
        int ret = init_yolov8_model(resolved.c_str(), &_app_ctx);
        if (ret >= 0) {
            rknn_set_core_mask(_app_ctx.rknn_ctx, RKNN_NPU_CORE_0_1);
            size_t raw_size = (size_t)_app_ctx.model_width * _app_ctx.model_height * _app_ctx.model_channel;
            _input_buf_size = ((raw_size + 4095) / 4096) * 4096 + 4096;
            posix_memalign(&_input_buf, 4096, _input_buf_size);
            load_labels("");
            _is_initialized = true;
        }
    }
    return infer_internal(img, results);
}

int NpuInfer::detect_frame(VpuDecoder* decoder, int ch, char* out_buf, int out_buf_size, unsigned long long* out_frame_idx, long long* out_pts_ms) {
    if (!out_buf || out_buf_size <= 0) return -1;
    std::lock_guard<std::mutex> lock(_infer_mutex);

    if (!_is_initialized) {
        std::string resolved = find_model_path("");
        init_post_process();
        int ret = init_yolov8_model(resolved.c_str(), &_app_ctx);
        if (ret < 0) {
            snprintf(out_buf, out_buf_size, "{\"frame_width\":0,\"frame_height\":0,\"detections\":[]}");
            return (int)strlen(out_buf);
        }
        rknn_set_core_mask(_app_ctx.rknn_ctx, RKNN_NPU_CORE_0_1);
        size_t raw_size = (size_t)_app_ctx.model_width * _app_ctx.model_height * _app_ctx.model_channel;
        _input_buf_size = ((raw_size + 4095) / 4096) * 4096 + 4096;
        posix_memalign(&_input_buf, 4096, _input_buf_size);
        load_labels("");
        _is_initialized = true;
    }

    if (!decoder) {
        snprintf(out_buf, out_buf_size, "{\"frame_width\":0,\"frame_height\":0,\"detections\":[]}");
        return (int)strlen(out_buf);
    }

    ensure_nv12_buffer_size(4 * 1024 * 1024);

    image_buffer_t frame;
    uint64_t frame_idx = 0;
    int64_t pts_ms = 0;

    if (!decoder->get_latest_frame(_nv12_buf, _nv12_buf_size, frame, frame_idx, pts_ms)) {
        snprintf(out_buf, out_buf_size, "{\"frame_width\":0,\"frame_height\":0,\"detections\":[]}");
        return (int)strlen(out_buf);
    }

    if (out_frame_idx) *out_frame_idx = frame_idx;
    if (out_pts_ms) *out_pts_ms = pts_ms;

    struct timespec ts_start, ts_end;
    clock_gettime(CLOCK_MONOTONIC, &ts_start);

    object_detect_result_list results;
    memset(&results, 0, sizeof(results));

    bool infer_ok = infer_internal(frame, results);
    if (!infer_ok) {
        snprintf(out_buf, out_buf_size, "{\"frame_width\":%d,\"frame_height\":%d,\"detections\":[]}", frame.width, frame.height);
        return (int)strlen(out_buf);
    }

    clock_gettime(CLOCK_MONOTONIC, &ts_end);
    double cost_ms = (ts_end.tv_sec - ts_start.tv_sec) * 1000.0 + (ts_end.tv_nsec - ts_start.tv_nsec) / 1000000.0;

    std::string json;
    json.reserve(2048);
    char tmp[512];

    snprintf(tmp, sizeof(tmp), "{\"frame_width\": %d, \"frame_height\": %d, \"frame_idx\": %llu, \"pts_ms\": %lld, \"detections\": [",
             frame.width, frame.height, (unsigned long long)frame_idx, (long long)pts_ms);
    json.append(tmp);

    for (int i = 0; i < results.count; i++) {
        int cls_id = results.results[i].cls_id;
        const char* label = get_label_name(cls_id);
        int x1 = results.results[i].box.left;
        int y1 = results.results[i].box.top;
        int x2 = results.results[i].box.right;
        int y2 = results.results[i].box.bottom;
        float conf = results.results[i].prop;

        float rx1 = (frame.width > 0) ? ((float)x1 / (float)frame.width) : 0.0f;
        float ry1 = (frame.height > 0) ? ((float)y1 / (float)frame.height) : 0.0f;
        float rx2 = (frame.width > 0) ? ((float)x2 / (float)frame.width) : 0.0f;
        float ry2 = (frame.height > 0) ? ((float)y2 / (float)frame.height) : 0.0f;

        if (rx1 < 0.0f) rx1 = 0.0f; else if (rx1 > 1.0f) rx1 = 1.0f;
        if (ry1 < 0.0f) ry1 = 0.0f; else if (ry1 > 1.0f) ry1 = 1.0f;
        if (rx2 < 0.0f) rx2 = 0.0f; else if (rx2 > 1.0f) rx2 = 1.0f;
        if (ry2 < 0.0f) ry2 = 0.0f; else if (ry2 > 1.0f) ry2 = 1.0f;

        snprintf(tmp, sizeof(tmp),
            "%s{\"class_id\": %d, \"label\": \"%s\", \"confidence\": %.2f, \"rel_box\": [%.4f, %.4f, %.4f, %.4f], \"box\": [%d, %d, %d, %d]}",
            (i > 0 ? ", " : ""),
            cls_id, (label ? label : "object"), conf, rx1, ry1, rx2, ry2, x1, y1, x2, y2
        );
        json.append(tmp);
    }
    json.append("]}");

    if ((int)json.size() >= out_buf_size) {
        snprintf(out_buf, out_buf_size, "{\"frame_width\":%d,\"frame_height\":%d,\"detections\":[]}", frame.width, frame.height);
        return (int)strlen(out_buf);
    }

    memcpy(out_buf, json.c_str(), json.size() + 1);

    static int s_latest_cnt = 0;
    if (++s_latest_cnt % 90 == 0) {
        printf("[detect_lib] [ch %d] latest infer #%d (cost=%.2fms, targets=%d, f#%llu, pts=%lldms)\n",
               ch, s_latest_cnt, cost_ms, results.count, (unsigned long long)frame_idx, (long long)pts_ms);
        fflush(stdout);
    }

    return (int)json.size();
}

const char* NpuInfer::get_label_name(int cls_id) {
    if (cls_id >= 0 && cls_id < (int)_labels.size()) {
        return _labels[cls_id].c_str();
    }
    const char* name = coco_cls_to_name(cls_id);
    if (name && strcmp(name, "null") != 0) {
        return name;
    }
    return "object";
}

void NpuInfer::release() {
    std::lock_guard<std::mutex> lock(_infer_mutex);
    if (_is_initialized) {
        deinit_post_process();
        release_yolov8_model(&_app_ctx);
        if (_input_buf) {
            free(_input_buf);
            _input_buf = nullptr;
            _input_buf_size = 0;
        }
        if (_nv12_buf) {
            free(_nv12_buf);
            _nv12_buf = nullptr;
            _nv12_buf_size = 0;
        }
        _is_initialized = false;
        _labels.clear();
        printf("[npu_infer] npu resources released.\n");
    }
}
```

include/hardware/vpu_decoder.h

```c
#pragma once

#include "rk_mpi.h"
#include "rk_mpi_cmd.h"
#include "mpp_buffer.h"
#include "mpp_frame.h"
#include "mpp_packet.h"
#include "mpp_err.h"
#include "image_utils.h"
#include <vector>
#include <mutex>
#include <cstdint>
#include <cstddef>

class VpuDecoder {
public:
    VpuDecoder();
    ~VpuDecoder();

    bool decode_raw_buffer(const unsigned char* data, int width, int height, int channels, image_buffer_t& frame);
    bool feed_h264_packet(const unsigned char* packet_data, size_t packet_size, uint64_t frame_idx = 0, int64_t pts_ms = 0);
    bool get_latest_frame(std::vector<unsigned char>& out_buffer, image_buffer_t& frame, uint64_t& out_frame_idx, int64_t& out_pts_ms);
    bool get_latest_frame(void* out_buffer, size_t out_buf_capacity, image_buffer_t& frame, uint64_t& out_frame_idx, int64_t& out_pts_ms);

private:
    bool init_mpp();
    void release_mpp();
    bool decode_h264_packet(const unsigned char* packet_data, size_t packet_size, image_buffer_t& frame, uint64_t frame_idx = 0, int64_t pts_ms = 0);
    void drain_frames(bool& got_new_frame, uint64_t frame_idx = 0, int64_t pts_ms = 0);

    void* _mpp_handle;
    MppCtx _ctx;
    MppApi* _mpi;
    MppBufferGroup _frm_grp;
    MppPacket _packet;
    bool _is_mpp_inited;

    std::mutex _decode_mutex;
    std::vector<unsigned char> _feed_buf;
    std::mutex _frame_mutex;
    std::vector<unsigned char> _last_nv12_frame;
    int _last_width;
    int _last_height;
    int _last_hor_stride;
    int _last_ver_stride;
    int _last_fd;
    uint64_t _last_frame_idx;
    int64_t _last_pts_ms;

    MPP_RET (*_p_mpp_create)(MppCtx *, MppApi **);
    MPP_RET (*_p_mpp_init)(MppCtx, MppCtxType, MppCodingType);
    MPP_RET (*_p_mpp_destroy)(MppCtx);
    MPP_RET (*_p_mpp_packet_init)(MppPacket *, void *, size_t);
    MPP_RET (*_p_mpp_packet_deinit)(MppPacket *);
    void (*_p_mpp_packet_set_data)(MppPacket, void *);
    void (*_p_mpp_packet_set_size)(MppPacket, size_t);
    void (*_p_mpp_packet_set_pos)(MppPacket, void *);
    void (*_p_mpp_packet_set_length)(MppPacket, size_t);
    MPP_RET (*_p_mpp_frame_init)(MppFrame *);
    MPP_RET (*_p_mpp_frame_deinit)(MppFrame *);
    RK_U32 (*_p_mpp_frame_get_info_change)(MppFrame);
    RK_U32 (*_p_mpp_frame_get_errinfo)(MppFrame);
    RK_U32 (*_p_mpp_frame_get_discard)(MppFrame);
    MppBuffer (*_p_mpp_frame_get_buffer)(MppFrame);
    RK_U32 (*_p_mpp_frame_get_width)(MppFrame);
    RK_U32 (*_p_mpp_frame_get_height)(MppFrame);
    RK_U32 (*_p_mpp_frame_get_hor_stride)(MppFrame);
    RK_U32 (*_p_mpp_frame_get_ver_stride)(MppFrame);
    RK_U32 (*_p_mpp_frame_get_buf_size)(MppFrame);
    MppFrameFormat (*_p_mpp_frame_get_fmt)(MppFrame);
    void* (*_p_mpp_buffer_get_ptr_with_caller)(MppBuffer, const char *);
    int (*_p_mpp_buffer_get_fd_with_caller)(MppBuffer, const char *);
    size_t (*_p_mpp_buffer_get_size_with_caller)(MppBuffer, const char *);
    MPP_RET (*_p_mpp_buffer_group_get)(MppBufferGroup *, MppBufferType, MppBufferMode, const char *, const char *);
    MPP_RET (*_p_mpp_buffer_group_limit_config)(MppBufferGroup, size_t, RK_S32);
    MPP_RET (*_p_mpp_buffer_group_put)(MppBufferGroup);
    MPP_RET (*_p_mpp_buffer_group_clear)(MppBufferGroup);
};
```

src/hardware/vpu_decoder.cc

```c
#include "hardware/vpu_decoder.h"
#include "consts.h"
#include "utils/image_utils.h"
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <dlfcn.h>
#include <unistd.h>

VpuDecoder::VpuDecoder()
    : _mpp_handle(nullptr),
      _ctx(nullptr),
      _mpi(nullptr),
      _frm_grp(nullptr),
      _packet(nullptr),
      _is_mpp_inited(false),
      _last_width(0),
      _last_height(0),
      _last_hor_stride(0),
      _last_ver_stride(0),
      _last_fd(-1),
      _last_frame_idx(0),
      _last_pts_ms(0) {
    _feed_buf.reserve(2 * 1024 * 1024);
    _last_nv12_frame.reserve(8 * 1024 * 1024);
}

VpuDecoder::~VpuDecoder() {
    release_mpp();
}

bool VpuDecoder::init_mpp() {
    if (_is_mpp_inited) {
        return true;
    }

    _mpp_handle = dlopen(MPP_LIB_NAME, RTLD_LAZY | RTLD_GLOBAL);
    if (!_mpp_handle) {
        _mpp_handle = dlopen("librockchip_mpp.so.1", RTLD_LAZY | RTLD_GLOBAL);
    }

    if (!_mpp_handle) {
        printf("[vpu_decoder] mpp library not found.\n");
        return false;
    }

    _p_mpp_create = (MPP_RET (*)(MppCtx *, MppApi **))dlsym(_mpp_handle, "mpp_create");
    _p_mpp_init = (MPP_RET (*)(MppCtx, MppCtxType, MppCodingType))dlsym(_mpp_handle, "mpp_init");
    _p_mpp_destroy = (MPP_RET (*)(MppCtx))dlsym(_mpp_handle, "mpp_destroy");
    _p_mpp_packet_init = (MPP_RET (*)(MppPacket *, void *, size_t))dlsym(_mpp_handle, "mpp_packet_init");
    _p_mpp_packet_deinit = (MPP_RET (*)(MppPacket *))dlsym(_mpp_handle, "mpp_packet_deinit");
    _p_mpp_packet_set_data = (void (*)(MppPacket, void *))dlsym(_mpp_handle, "mpp_packet_set_data");
    _p_mpp_packet_set_size = (void (*)(MppPacket, size_t))dlsym(_mpp_handle, "mpp_packet_set_size");
    _p_mpp_packet_set_pos = (void (*)(MppPacket, void *))dlsym(_mpp_handle, "mpp_packet_set_pos");
    _p_mpp_packet_set_length = (void (*)(MppPacket, size_t))dlsym(_mpp_handle, "mpp_packet_set_length");
    _p_mpp_frame_init = (MPP_RET (*)(MppFrame *))dlsym(_mpp_handle, "mpp_frame_init");
    _p_mpp_frame_deinit = (MPP_RET (*)(MppFrame *))dlsym(_mpp_handle, "mpp_frame_deinit");
    _p_mpp_frame_get_info_change = (RK_U32 (*)(MppFrame))dlsym(_mpp_handle, "mpp_frame_get_info_change");
    _p_mpp_frame_get_errinfo = (RK_U32 (*)(MppFrame))dlsym(_mpp_handle, "mpp_frame_get_errinfo");
    _p_mpp_frame_get_discard = (RK_U32 (*)(MppFrame))dlsym(_mpp_handle, "mpp_frame_get_discard");
    _p_mpp_frame_get_buffer = (MppBuffer (*)(MppFrame))dlsym(_mpp_handle, "mpp_frame_get_buffer");
    _p_mpp_frame_get_width = (RK_U32 (*)(MppFrame))dlsym(_mpp_handle, "mpp_frame_get_width");
    _p_mpp_frame_get_height = (RK_U32 (*)(MppFrame))dlsym(_mpp_handle, "mpp_frame_get_height");
    _p_mpp_frame_get_hor_stride = (RK_U32 (*)(MppFrame))dlsym(_mpp_handle, "mpp_frame_get_hor_stride");
    _p_mpp_frame_get_ver_stride = (RK_U32 (*)(MppFrame))dlsym(_mpp_handle, "mpp_frame_get_ver_stride");
    _p_mpp_frame_get_buf_size = (RK_U32 (*)(MppFrame))dlsym(_mpp_handle, "mpp_frame_get_buf_size");
    _p_mpp_frame_get_fmt = (MppFrameFormat (*)(MppFrame))dlsym(_mpp_handle, "mpp_frame_get_fmt");

    _p_mpp_buffer_get_ptr_with_caller = (void* (*)(MppBuffer, const char *))dlsym(_mpp_handle, "mpp_buffer_get_ptr_with_caller");
    if (!_p_mpp_buffer_get_ptr_with_caller) {
        _p_mpp_buffer_get_ptr_with_caller = (void* (*)(MppBuffer, const char *))dlsym(_mpp_handle, "mpp_buffer_get_ptr");
    }

    _p_mpp_buffer_get_fd_with_caller = (int (*)(MppBuffer, const char *))dlsym(_mpp_handle, "mpp_buffer_get_fd_with_caller");
    if (!_p_mpp_buffer_get_fd_with_caller) {
        _p_mpp_buffer_get_fd_with_caller = (int (*)(MppBuffer, const char *))dlsym(_mpp_handle, "mpp_buffer_get_fd");
    }

    _p_mpp_buffer_get_size_with_caller = (size_t (*)(MppBuffer, const char *))dlsym(_mpp_handle, "mpp_buffer_get_size_with_caller");
    if (!_p_mpp_buffer_get_size_with_caller) {
        _p_mpp_buffer_get_size_with_caller = (size_t (*)(MppBuffer, const char *))dlsym(_mpp_handle, "mpp_buffer_get_size");
    }

    _p_mpp_buffer_group_get = (MPP_RET (*)(MppBufferGroup *, MppBufferType, MppBufferMode, const char *, const char *))dlsym(_mpp_handle, "mpp_buffer_group_get");
    _p_mpp_buffer_group_limit_config = (MPP_RET (*)(MppBufferGroup, size_t, RK_S32))dlsym(_mpp_handle, "mpp_buffer_group_limit_config");
    _p_mpp_buffer_group_put = (MPP_RET (*)(MppBufferGroup))dlsym(_mpp_handle, "mpp_buffer_group_put");
    _p_mpp_buffer_group_clear = (MPP_RET (*)(MppBufferGroup))dlsym(_mpp_handle, "mpp_buffer_group_clear");

    printf("[vpu_decoder] symbols: get_ptr=%p, get_fd=%p, get_size=%p, get_fmt=%p\n",
           _p_mpp_buffer_get_ptr_with_caller, _p_mpp_buffer_get_fd_with_caller, _p_mpp_buffer_get_size_with_caller, _p_mpp_frame_get_fmt);

    if (!_p_mpp_create || !_p_mpp_init || !_p_mpp_destroy || !_p_mpp_packet_init) {
        printf("[vpu_decoder] failed to resolve required mpp symbols.\n");
        dlclose(_mpp_handle);
        _mpp_handle = nullptr;
        return false;
    }

    MPP_RET ret = _p_mpp_create(&_ctx, &_mpi);
    if (ret != MPP_OK || !_ctx || !_mpi) {
        printf("[vpu_decoder] mpp_create failed (%d)\n", ret);
        return false;
    }

    ret = _p_mpp_init(_ctx, MPP_CTX_DEC, MPP_VIDEO_CodingAVC);
    if (ret != MPP_OK) {
        printf("[vpu_decoder] mpp_init dec avc failed (%d)\n", ret);
        _p_mpp_destroy(_ctx);
        _ctx = nullptr;
        _mpi = nullptr;
        return false;
    }

    RK_U32 need_split = 1;
    _mpi->control(_ctx, MPP_DEC_SET_PARSER_SPLIT_MODE, &need_split);

    RK_U32 fast_mode = 1;
    _mpi->control(_ctx, MPP_DEC_SET_PARSER_FAST_MODE, &fast_mode);

    RK_U32 immediate_out = 1;
    _mpi->control(_ctx, MPP_DEC_SET_IMMEDIATE_OUT, &immediate_out);

    RK_U32 fast_play = 1;
    _mpi->control(_ctx, MPP_DEC_SET_ENABLE_FAST_PLAY, &fast_play);

    MppFrameFormat out_fmt = MPP_FMT_YUV420SP;
    int set_fmt_ret = _mpi->control(_ctx, MPP_DEC_SET_OUTPUT_FORMAT, &out_fmt);
    printf("[vpu_decoder] mpp_dec_set_output_format ret=%d, immediate_out=1\n", set_fmt_ret);

    ret = _p_mpp_packet_init(&_packet, nullptr, 0);
    if (ret != MPP_OK) {
        printf("[vpu_decoder] mpp_packet_init failed (%d)\n", ret);
        return false;
    }

    _frm_grp = nullptr;
    _is_mpp_inited = true;
    printf("[vpu_decoder] vpu hardware decoder initialized (cmd_base=0x%08x).\n", MPP_DEC_CMD_BASE);
    return true;
}

void VpuDecoder::release_mpp() {
    if (_packet && _p_mpp_packet_deinit) {
        _p_mpp_packet_deinit(&_packet);
        _packet = nullptr;
    }
    if (_frm_grp && _p_mpp_buffer_group_put) {
        _p_mpp_buffer_group_put(_frm_grp);
        _frm_grp = nullptr;
    }
    if (_is_mpp_inited && _ctx) {
        if (_p_mpp_destroy) {
            _p_mpp_destroy(_ctx);
        }
        _ctx = nullptr;
        _mpi = nullptr;
        _is_mpp_inited = false;
    }
    if (_mpp_handle) {
        dlclose(_mpp_handle);
        _mpp_handle = nullptr;
    }
}

void VpuDecoder::drain_frames(bool& got_new_frame, uint64_t frame_idx, int64_t pts_ms) {
    if (!_is_mpp_inited || !_mpi || !_ctx) {
        return;
    }
    while (true) {
        MppFrame mpp_frame = nullptr;
        MPP_RET ret = _mpi->decode_get_frame(_ctx, &mpp_frame);
        if (ret != MPP_OK || !mpp_frame) {
            break;
        }

        uint32_t is_info_change = _p_mpp_frame_get_info_change ? _p_mpp_frame_get_info_change(mpp_frame) : 0;
        uint32_t errinfo = _p_mpp_frame_get_errinfo ? _p_mpp_frame_get_errinfo(mpp_frame) : 0;
        uint32_t discard = _p_mpp_frame_get_discard ? _p_mpp_frame_get_discard(mpp_frame) : 0;
        MppBuffer buffer = _p_mpp_frame_get_buffer ? _p_mpp_frame_get_buffer(mpp_frame) : nullptr;
        uint32_t width = _p_mpp_frame_get_width ? _p_mpp_frame_get_width(mpp_frame) : 0;
        uint32_t height = _p_mpp_frame_get_height ? _p_mpp_frame_get_height(mpp_frame) : 0;
        uint32_t hor_stride = _p_mpp_frame_get_hor_stride ? _p_mpp_frame_get_hor_stride(mpp_frame) : width;
        uint32_t ver_stride = _p_mpp_frame_get_ver_stride ? _p_mpp_frame_get_ver_stride(mpp_frame) : height;

        static int s_frame_poll_count = 0;
        s_frame_poll_count++;

        if (is_info_change) {
            size_t buf_size = _p_mpp_frame_get_buf_size ? _p_mpp_frame_get_buf_size(mpp_frame) : 0;
            if (buf_size == 0) {
                buf_size = hor_stride * ver_stride * 3 / 2;
            }
            printf("[vpu_decoder] info change event #%d: %ux%u (stride: %ux%u, buf_size: %zu)\n",
                   s_frame_poll_count, width, height, hor_stride, ver_stride, buf_size);

            if (_frm_grp == nullptr) {
                if (_p_mpp_buffer_group_get) {
                    ret = _p_mpp_buffer_group_get(&_frm_grp, MPP_BUFFER_TYPE_DRM, MPP_BUFFER_INTERNAL, NULL, NULL);
                    if (ret != MPP_OK || !_frm_grp) {
                        ret = _p_mpp_buffer_group_get(&_frm_grp, MPP_BUFFER_TYPE_DMA_HEAP, MPP_BUFFER_INTERNAL, NULL, NULL);
                    }
                    if (ret != MPP_OK || !_frm_grp) {
                        ret = _p_mpp_buffer_group_get(&_frm_grp, MPP_BUFFER_TYPE_ION, MPP_BUFFER_INTERNAL, NULL, NULL);
                    }
                }
                int r_ext = _mpi->control(_ctx, MPP_DEC_SET_EXT_BUF_GROUP, _frm_grp);
                printf("[vpu_decoder] created frm_grp=%p, set_ext_buf_group (0x%08x) ret=%d\n",
                       _frm_grp, MPP_DEC_SET_EXT_BUF_GROUP, r_ext);
            } else {
                if (_p_mpp_buffer_group_clear) {
                    _p_mpp_buffer_group_clear(_frm_grp);
                }
            }

            if (_frm_grp && _p_mpp_buffer_group_limit_config) {
                _p_mpp_buffer_group_limit_config(_frm_grp, buf_size, 24);
            }

            int cr = _mpi->control(_ctx, MPP_DEC_SET_INFO_CHANGE_READY, nullptr);
            printf("[vpu_decoder] mpp_dec_set_info_change_ready (0x%08x) ret=%d\n", MPP_DEC_SET_INFO_CHANGE_READY, cr);

            if (_p_mpp_frame_deinit) {
                _p_mpp_frame_deinit(&mpp_frame);
            }
            continue;
        }

        if (errinfo) {
            static int s_err_cnt = 0;
            if (s_err_cnt++ % 30 == 0) {
                printf("[vpu_decoder] frame #%d errinfo=0x%x\n", s_frame_poll_count, errinfo);
            }
        }

        if (discard) {
            if (_p_mpp_frame_deinit) {
                _p_mpp_frame_deinit(&mpp_frame);
            }
            continue;
        }

        if (buffer && width > 0 && height > 0) {
            void* ptr = _p_mpp_buffer_get_ptr_with_caller ? _p_mpp_buffer_get_ptr_with_caller(buffer, "drain_frames") : nullptr;
            size_t buf_size = _p_mpp_buffer_get_size_with_caller ? _p_mpp_buffer_get_size_with_caller(buffer, "drain_frames") : 0;
            int fd = _p_mpp_buffer_get_fd_with_caller ? _p_mpp_buffer_get_fd_with_caller(buffer, "drain_frames") : -1;
            if (buf_size == 0) {
                buf_size = hor_stride * ver_stride * 3 / 2;
            }

            if (ptr && buf_size > 0) {
                {
                    std::lock_guard<std::mutex> lock(_frame_mutex);
                    if (_last_nv12_frame.size() < buf_size) {
                        _last_nv12_frame.resize(buf_size);
                    }
                    memcpy(_last_nv12_frame.data(), ptr, buf_size);
                    _last_width = (int)width;
                    _last_height = (int)height;
                    _last_hor_stride = (int)hor_stride;
                    _last_ver_stride = (int)ver_stride;
                    _last_fd = fd;
                    _last_frame_idx = frame_idx;
                    _last_pts_ms = pts_ms;
                }
                got_new_frame = true;

                static bool s_logged_first = false;
                if (!s_logged_first) {
                    MppFrameFormat fmt = _p_mpp_frame_get_fmt ? _p_mpp_frame_get_fmt(mpp_frame) : MPP_FMT_YUV420SP;
                    printf("[vpu_decoder] first video frame decoded: %dx%d (stride: %dx%d, size: %zu, fd: %d, fmt=0x%08x)\n",
                           _last_width, _last_height, _last_hor_stride, _last_ver_stride, buf_size, fd, (unsigned int)fmt);
                    fflush(stdout);
                    s_logged_first = true;
                }
            } else {
                static int s_nobuf_cnt = 0;
                if (s_nobuf_cnt++ % 30 == 0) {
                    printf("[vpu_decoder] frame #%d buffer valid but ptr=%p, fd=%d, size=%zu\n",
                           s_frame_poll_count, ptr, fd, buf_size);
                    fflush(stdout);
                }
            }
        }

        if (_p_mpp_frame_deinit) {
            _p_mpp_frame_deinit(&mpp_frame);
        }
    }
}

bool VpuDecoder::decode_h264_packet(const unsigned char* _packetdata, size_t packet_size, image_buffer_t& frame, uint64_t frame_idx, int64_t pts_ms) {
    std::lock_guard<std::mutex> lock(_decode_mutex);
    if (!_is_mpp_inited) {
        if (!init_mpp()) {
            return false;
        }
    }

    if (!_packetdata || packet_size == 0 || !_mpi || !_packet) {
        return false;
    }

    const unsigned char* feed_ptr = _packetdata;
    size_t feed_size = packet_size;

    if (packet_size >= 4) {
        bool has_start_code = (_packetdata[0] == 0 && _packetdata[1] == 0 && _packetdata[2] == 0 && _packetdata[3] == 1) ||
                              (_packetdata[0] == 0 && _packetdata[1] == 0 && _packetdata[2] == 1);
        if (!has_start_code) {
            _feed_buf.clear();
            _feed_buf.reserve(packet_size + 4);
            _feed_buf.push_back(0x00);
            _feed_buf.push_back(0x00);
            _feed_buf.push_back(0x00);
            _feed_buf.push_back(0x01);
            _feed_buf.insert(_feed_buf.end(), _packetdata, _packetdata + packet_size);
            feed_ptr = _feed_buf.data();
            feed_size = _feed_buf.size();
        }
    }

    if (_p_mpp_packet_set_data) _p_mpp_packet_set_data(_packet, const_cast<unsigned char*>(feed_ptr));
    if (_p_mpp_packet_set_size) _p_mpp_packet_set_size(_packet, feed_size);
    if (_p_mpp_packet_set_pos) _p_mpp_packet_set_pos(_packet, const_cast<unsigned char*>(feed_ptr));
    if (_p_mpp_packet_set_length) _p_mpp_packet_set_length(_packet, feed_size);

    bool got_new_frame = false;

    drain_frames(got_new_frame, frame_idx, pts_ms);

    int put_ret = -1;
    for (int retry = 0; retry < 5; retry++) {
        put_ret = _mpi->decode_put_packet(_ctx, _packet);
        if (put_ret == MPP_OK) {
            break;
        }
        if (put_ret == MPP_ERR_BUFFER_FULL) {
            drain_frames(got_new_frame, frame_idx, pts_ms);
            usleep(1000);
            continue;
        }
        break;
    }

    if (put_ret != MPP_OK && put_ret != MPP_ERR_BUFFER_FULL) {
        static int s_put_fail = 0;
        if (s_put_fail++ % 30 == 0) {
            printf("[vpu_decoder] decode_put_packet failed (%d, size=%zu)\n", put_ret, feed_size);
            fflush(stdout);
        }
    }

    for (int retry = 0; retry < 15; retry++) {
        drain_frames(got_new_frame, frame_idx, pts_ms);
        if (got_new_frame) {
            break;
        }
        usleep(1000);
    }

    std::lock_guard<std::mutex> lk_frm(_frame_mutex);
    if (got_new_frame && !_last_nv12_frame.empty() && _last_width > 0 && _last_height > 0) {
        memset(&frame, 0, sizeof(image_buffer_t));
        frame.width = _last_width;
        frame.height = _last_height;
        frame.width_stride = _last_hor_stride > 0 ? _last_hor_stride : _last_width;
        frame.height_stride = _last_ver_stride > 0 ? _last_ver_stride : _last_height;
        frame.format = IMAGE_FORMAT_YUV420SP_NV12;
        frame.virt_addr = _last_nv12_frame.data();
        frame.fd = -1;
        frame.size = (int)_last_nv12_frame.size();
        return true;
    }

    return false;
}

bool VpuDecoder::feed_h264_packet(const unsigned char* _packetdata, size_t packet_size, uint64_t frame_idx, int64_t pts_ms) {
    std::lock_guard<std::mutex> lock(_decode_mutex);
    if (!_is_mpp_inited) {
        if (!init_mpp()) {
            return false;
        }
    }

    if (!_packetdata || packet_size == 0 || !_mpi || !_packet) {
        return false;
    }

    const unsigned char* feed_ptr = _packetdata;
    size_t feed_size = packet_size;

    if (packet_size >= 4) {
        bool has_start_code = (_packetdata[0] == 0 && _packetdata[1] == 0 && _packetdata[2] == 0 && _packetdata[3] == 1) ||
                              (_packetdata[0] == 0 && _packetdata[1] == 0 && _packetdata[2] == 1);
        if (!has_start_code) {
            _feed_buf.clear();
            _feed_buf.reserve(packet_size + 4);
            _feed_buf.push_back(0x00);
            _feed_buf.push_back(0x00);
            _feed_buf.push_back(0x00);
            _feed_buf.push_back(0x01);
            _feed_buf.insert(_feed_buf.end(), _packetdata, _packetdata + packet_size);
            feed_ptr = _feed_buf.data();
            feed_size = _feed_buf.size();
        }
    }

    if (_p_mpp_packet_set_data) _p_mpp_packet_set_data(_packet, const_cast<unsigned char*>(feed_ptr));
    if (_p_mpp_packet_set_size) _p_mpp_packet_set_size(_packet, feed_size);
    if (_p_mpp_packet_set_pos) _p_mpp_packet_set_pos(_packet, const_cast<unsigned char*>(feed_ptr));
    if (_p_mpp_packet_set_length) _p_mpp_packet_set_length(_packet, feed_size);

    bool got_new_frame = false;

    drain_frames(got_new_frame, frame_idx, pts_ms);

    int put_ret = _mpi->decode_put_packet(_ctx, _packet);
    if (put_ret == MPP_ERR_BUFFER_FULL) {
        drain_frames(got_new_frame, frame_idx, pts_ms);
        _mpi->decode_put_packet(_ctx, _packet);
    }

    drain_frames(got_new_frame, frame_idx, pts_ms);

    return true;
}

bool VpuDecoder::get_latest_frame(std::vector<unsigned char>& out_buffer, image_buffer_t& frame, uint64_t& out_frame_idx, int64_t& out_pts_ms) {
    std::lock_guard<std::mutex> lock(_frame_mutex);
    if (_last_nv12_frame.empty() || _last_width <= 0 || _last_height <= 0) {
        return false;
    }
    size_t cur_sz = (size_t)_last_hor_stride * _last_ver_stride * 3 / 2;
    if (cur_sz == 0 || cur_sz > _last_nv12_frame.size()) {
        cur_sz = _last_nv12_frame.size();
    }
    if (out_buffer.size() < cur_sz) {
        out_buffer.resize(cur_sz);
    }
    memcpy(out_buffer.data(), _last_nv12_frame.data(), cur_sz);

    memset(&frame, 0, sizeof(image_buffer_t));
    frame.width = _last_width;
    frame.height = _last_height;
    frame.width_stride = _last_hor_stride > 0 ? _last_hor_stride : _last_width;
    frame.height_stride = _last_ver_stride > 0 ? _last_ver_stride : _last_height;
    frame.format = IMAGE_FORMAT_YUV420SP_NV12;
    frame.virt_addr = out_buffer.data();
    frame.fd = -1;
    frame.size = (int)cur_sz;
    out_frame_idx = _last_frame_idx;
    out_pts_ms = _last_pts_ms;
    return true;
}

bool VpuDecoder::get_latest_frame(void* out_buffer, size_t out_buf_capacity, image_buffer_t& frame, uint64_t& out_frame_idx, int64_t& out_pts_ms) {
    if (!out_buffer || out_buf_capacity == 0) {
        return false;
    }
    std::lock_guard<std::mutex> lock(_frame_mutex);
    if (_last_nv12_frame.empty() || _last_width <= 0 || _last_height <= 0) {
        return false;
    }
    size_t cur_sz = (size_t)_last_hor_stride * _last_ver_stride * 3 / 2;
    if (cur_sz == 0 || cur_sz > _last_nv12_frame.size()) {
        cur_sz = _last_nv12_frame.size();
    }
    if (out_buf_capacity < cur_sz) {
        return false;
    }
    memcpy(out_buffer, _last_nv12_frame.data(), cur_sz);

    memset(&frame, 0, sizeof(image_buffer_t));
    frame.width = _last_width;
    frame.height = _last_height;
    frame.width_stride = _last_hor_stride > 0 ? _last_hor_stride : _last_width;
    frame.height_stride = _last_ver_stride > 0 ? _last_ver_stride : _last_height;
    frame.format = IMAGE_FORMAT_YUV420SP_NV12;
    frame.virt_addr = (unsigned char*)out_buffer;
    frame.fd = -1;
    frame.size = (int)cur_sz;
    out_frame_idx = _last_frame_idx;
    out_pts_ms = _last_pts_ms;
    return true;
}

bool VpuDecoder::decode_raw_buffer(const unsigned char* data, int width, int height, int channels, image_buffer_t& frame) {
    if (!data) {
        return false;
    }

    if (channels == 0) {
        size_t packet_size = (width > 0) ? (size_t)width : 0;
        bool ok = decode_h264_packet(data, packet_size, frame);
        if (!ok) {
            static int s_dec_fail = 0;
            if (s_dec_fail++ % 30 == 0) {
                printf("[vpu_decoder] decode_h264_packet returned false (pkt_size=%zu, inited=%d, has_last_frame=%d)\n",
                       packet_size, (int)_is_mpp_inited, (int)!_last_nv12_frame.empty());
                fflush(stdout);
            }
        }
        return ok;
    }

    if (width <= 0 || height <= 0) {
        return false;
    }

    memset(&frame, 0, sizeof(image_buffer_t));
    frame.width = width;
    frame.height = height;
    frame.virt_addr = const_cast<unsigned char*>(data);

    if (channels == 12) {
        frame.format = IMAGE_FORMAT_YUV420SP_NV12;
    } else if (channels == 4) {
        frame.format = IMAGE_FORMAT_RGBA8888;
    } else if (channels == 1) {
        frame.format = IMAGE_FORMAT_GRAY8;
    } else {
        frame.format = IMAGE_FORMAT_RGB888;
    }
    frame.size = get_image_size(&frame);
    return true;
}
```

include/detect_cli.h

```c
#ifndef DETECT_CLI_H
#define DETECT_CLI_H

#ifdef __cplusplus
extern "C" {
#endif

int detect_file(const char* image_path, const char* out_json_path, const char* out_image_path);

#ifdef __cplusplus
}
#endif

#endif
```

src/detect_cli.cc

```c
#include "detect_cli.h"
#include "hardware/npu_infer.h"
#include "image_utils.h"
#include "file_utils.h"
#include "image_drawing.h"
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <unistd.h>
#include <string>

int detect_file(const char* image_path, const char* out_json_path, const char* out_image_path) {
    if (!image_path) return -1;

    image_buffer_t img;
    memset(&img, 0, sizeof(image_buffer_t));
    if (read_image(image_path, &img) != 0) {
        fprintf(stderr, "[detect_file] failed to read input image: %s\n", image_path);
        return -1;
    }

    object_detect_result_list results;
    memset(&results, 0, sizeof(results));

    if (!NpuInfer::shareInstance().infer(img, results)) {
        if (img.virt_addr) free(img.virt_addr);
        return -1;
    }

    std::string json;
    json.reserve(2048);
    char tmp[512];

    snprintf(tmp, sizeof(tmp), "{\"frame_width\": %d, \"frame_height\": %d, \"detections\": [",
             img.width, img.height);
    json.append(tmp);

    for (int i = 0; i < results.count; i++) {
        int cls_id = results.results[i].cls_id;
        const char* label = NpuInfer::shareInstance().get_label_name(cls_id);
        int x1 = results.results[i].box.left;
        int y1 = results.results[i].box.top;
        int x2 = results.results[i].box.right;
        int y2 = results.results[i].box.bottom;
        float conf = results.results[i].prop;

        float rx1 = (img.width > 0) ? ((float)x1 / (float)img.width) : 0.0f;
        float ry1 = (img.height > 0) ? ((float)y1 / (float)img.height) : 0.0f;
        float rx2 = (img.width > 0) ? ((float)x2 / (float)img.width) : 0.0f;
        float ry2 = (img.height > 0) ? ((float)y2 / (float)img.height) : 0.0f;

        if (rx1 < 0.0f) rx1 = 0.0f; else if (rx1 > 1.0f) rx1 = 1.0f;
        if (ry1 < 0.0f) ry1 = 0.0f; else if (ry1 > 1.0f) ry1 = 1.0f;
        if (rx2 < 0.0f) rx2 = 0.0f; else if (rx2 > 1.0f) rx2 = 1.0f;
        if (ry2 < 0.0f) ry2 = 0.0f; else if (ry2 > 1.0f) ry2 = 1.0f;

        snprintf(tmp, sizeof(tmp),
            "%s{\"class_id\": %d, \"label\": \"%s\", \"confidence\": %.2f, \"rel_box\": [%.4f, %.4f, %.4f, %.4f], \"box\": [%d, %d, %d, %d]}",
            (i > 0 ? ", " : ""),
            cls_id, (label ? label : "object"), conf, rx1, ry1, rx2, ry2, x1, y1, x2, y2
        );
        json.append(tmp);
    }
    json.append("]}");

    printf("[detect_file] targets: %d, json: %s\n", results.count, json.c_str());

    if (out_json_path && out_json_path[0] != '\0') {
        FILE* fp = fopen(out_json_path, "w");
        if (fp) {
            fputs(json.c_str(), fp);
            fclose(fp);
            printf("[detect_file] json results saved to: %s\n", out_json_path);
        }
    }

    if (out_image_path && out_image_path[0] != '\0') {
        char text[256];
        for (int i = 0; i < results.count; i++) {
            const object_detect_result& det = results.results[i];
            int x1 = det.box.left;
            int y1 = det.box.top;
            int x2 = det.box.right;
            int y2 = det.box.bottom;
            draw_rectangle(&img, x1, y1, x2 - x1, y2 - y1, COLOR_GREEN, 3);
            const char* label = NpuInfer::shareInstance().get_label_name(det.cls_id);
            snprintf(text, sizeof(text), "%s %.1f%%", (label ? label : "object"), det.prop * 100);
            draw_text(&img, text, x1, y1 - 20, COLOR_RED, 10);
        }
        write_image(out_image_path, &img);
        printf("[detect_file] annotated result image saved to: %s\n", out_image_path);
    }

    if (img.virt_addr) {
        free(img.virt_addr);
    }
    return results.count;
}

void print_help(const char* prog) {
    printf("=========================================================================\n");
    printf("  hardware detection cli utility\n");
    printf("=========================================================================\n");
    printf("usage:\n");
    printf("  %s <input_image> [output_image] [output_json]\n\n", prog);
    printf("arguments:\n");
    printf("  input_image   path to input image (.jpg / .png / .data) [required]\n");
    printf("  output_image  path to save annotated box image (default: ./result.jpg)\n");
    printf("  output_json   path to save detection json (default: ./result.json)\n\n");
    printf("examples:\n");
    printf("  %s /model/bus.jpg\n", prog);
    printf("  %s ./frame.jpg ./result.jpg ./result.json\n", prog);
    printf("=========================================================================\n");
}

int main(int argc, char* argv[]) {
    if (argc < 2 || strcmp(argv[1], "-h") == 0 || strcmp(argv[1], "--help") == 0) {
        print_help(argv[0]);
        return (argc < 2 ? 1 : 0);
    }

    const char* image_path = argv[1];
    const char* out_image  = (argc > 2) ? argv[2] : "./result.jpg";
    const char* out_json   = (argc > 3) ? argv[3] : "./result.json";

    if (access(image_path, R_OK) != 0) {
        fprintf(stderr, "[error] cannot access input image: %s\n", image_path);
        return 1;
    }

    printf("=========================================================\n");
    printf("  hardware detection running...\n");
    printf("=========================================================\n");
    printf("  • input image   : %s\n", image_path);
    printf("  • output image  : %s\n", out_image);
    printf("  • output json   : %s\n", out_json);
    printf("=========================================================\n\n");

    int ret = detect_file(image_path, out_json, out_image);
    if (ret >= 0) {
        printf("\n>>> [success] detection completed. result image and json generated.\n");
    } else {
        printf("\n>>> [failed] detection failed (code: %d).\n", ret);
    }
    return (ret >= 0 ? 0 : 1);
}
```

include/export.h

```c
#ifndef EXPORT_H
#define EXPORT_H

#ifdef __cplusplus
extern "C" {
#endif

int bin_to_img_stream(int ch, const unsigned char* packet_data, int packet_size, unsigned long long frame_idx, long long pts_ms);

int detect_img_bin(int ch, char* out_buf, int out_buf_size, unsigned long long* out_frame_idx, long long* out_pts_ms);

#ifdef __cplusplus
}
#endif

#endif
```

src/export.cc

```c
#include "export.h"
#include "hardware/vpu_decoder.h"
#include "hardware/channel_decoder.h"
#include "hardware/npu_infer.h"
#include <cstdio>
#include <cstring>

int bin_to_img_stream(int ch, const unsigned char* packet_data, int packet_size, unsigned long long frame_idx, long long pts_ms) {
    if (!packet_data || packet_size <= 0) return -1;
    VpuDecoder* decoder = ChannelDecoder::shareInstance().get_or_create(ch);
    if (!decoder) return -1;
    bool ok = decoder->feed_h264_packet(packet_data, (size_t)packet_size, (uint64_t)frame_idx, (int64_t)pts_ms);
    return ok ? 0 : -1;
}

int detect_img_bin(int ch, char* out_buf, int out_buf_size, unsigned long long* out_frame_idx, long long* out_pts_ms) {
    if (!out_buf || out_buf_size <= 0) return -1;
    VpuDecoder* decoder = ChannelDecoder::shareInstance().get_or_create(ch);
    if (!decoder) {
        snprintf(out_buf, out_buf_size, "{\"frame_width\":0,\"frame_height\":0,\"detections\":[]}");
        return (int)strlen(out_buf);
    }
    return NpuInfer::shareInstance().detect_frame(decoder, ch, out_buf, out_buf_size, out_frame_idx, out_pts_ms);
}
```

include/consts.h

```c
#ifndef CONSTS_H
#define CONSTS_H

#define LABEL_PATH       "model/coco_80_labels_list.txt"
#define MODEL_PATH       "model/yolov8.rknn"
#define MPP_LIB_NAME     "librockchip_mpp.so"

#endif
```

CMakeLists.txt

```c
cmake_minimum_required(VERSION 3.10)
project(detect_rknn C CXX)

set(CMAKE_C_STANDARD 99)
set(CMAKE_CXX_STANDARD 14)

set(RKNN_DIR ${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/rknn_model_zoo)
set(MPP_DIR  ${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/mpp)

include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${MPP_DIR}/inc
    ${RKNN_DIR}
    ${RKNN_DIR}/3rdparty/rknpu2/include
    ${RKNN_DIR}/3rdparty/librga/include
    ${RKNN_DIR}/3rdparty/stb_image
    ${RKNN_DIR}/utils
    ${RKNN_DIR}/examples/yolov8/cpp
)

add_definitions(-DENABLE_RKNN -DDISABLE_LIBJPEG)

set(SRCS
    src/export.cc
    src/hardware/npu_infer.cc
    src/hardware/vpu_decoder.cc
    src/hardware/channel_decoder.cc
    ${RKNN_DIR}/examples/yolov8/cpp/rknpu2/yolov8.cc
    ${RKNN_DIR}/examples/yolov8/cpp/postprocess.cc
    ${RKNN_DIR}/utils/image_utils.c
    ${RKNN_DIR}/utils/file_utils.c
    ${RKNN_DIR}/utils/image_drawing.c
)

add_library(detect_shared SHARED ${SRCS})
set_target_properties(detect_shared PROPERTIES OUTPUT_NAME "detect")
set_target_properties(detect_shared PROPERTIES BUILD_WITH_INSTALL_RPATH TRUE)
set_target_properties(detect_shared PROPERTIES INSTALL_RPATH "$ORIGIN:$ORIGIN/../lib:/usr/local/lib:/usr/lib")

set(LIBRKNNRT "${RKNN_DIR}/3rdparty/rknpu2/Linux/aarch64/librknnrt.so")
set(LIBRGA    "${RKNN_DIR}/3rdparty/librga/Linux/aarch64/librga.so")

target_link_libraries(detect_shared
    ${LIBRKNNRT}
    ${LIBRGA}
    pthread
    dl
    m
)

add_executable(detect_cli src/detect_cli.cc)
target_link_libraries(detect_cli detect_shared pthread dl m)
set_target_properties(detect_cli PROPERTIES BUILD_WITH_INSTALL_RPATH TRUE)
set_target_properties(detect_cli PROPERTIES INSTALL_RPATH "$ORIGIN:$ORIGIN/../lib:/usr/local/lib:/usr/lib")
```

build.sh

```sh
#!/bin/bash

set -e

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
TOOLCHAIN_DIR="${SCRIPT_DIR}/../toolchain"

if [ -d "${TOOLCHAIN_DIR}/bin" ]; then
    export PATH="${TOOLCHAIN_DIR}/bin:${PATH}"
    export CC=aarch64-none-linux-gnu-gcc
    export CXX=aarch64-none-linux-gnu-g++
fi

BUILD_DIR="${SCRIPT_DIR}/build"
mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"

cmake "${SCRIPT_DIR}" \
    -DCMAKE_SYSTEM_NAME=Linux \
    -DCMAKE_SYSTEM_PROCESSOR=aarch64 \
    -DCMAKE_C_COMPILER="${CC:-aarch64-none-linux-gnu-gcc}" \
    -DCMAKE_CXX_COMPILER="${CXX:-aarch64-none-linux-gnu-g++}" \
    -DCMAKE_BUILD_TYPE=Release

make -j$(nproc)
```
