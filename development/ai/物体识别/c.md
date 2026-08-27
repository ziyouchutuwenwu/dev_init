# c

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
│       │   │   ├── include
│       │   │   └── Linux
│       │   │       └── aarch64
│       │   ├── rknpu2
│       │   │   ├── include
│       │   │   └── Linux
│       │   │       └── aarch64
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

include/hardware/GpuRenderer.h

```h
#pragma once
#include "hardware/IGpuRenderer.h"

class GpuRenderer : public IGpuRenderer {
public:
    GpuRenderer() = default;
    ~GpuRenderer() override = default;

    void draw_detections(image_buffer_t& img, const object_detect_result_list& results) override;
};
```

include/hardware/IAIEngine.h

```h
#pragma once
#include "image_utils.h"
#include "yolov8.h"
#include "postprocess.h"
#include <string>

class IAIEngine {
public:
    virtual ~IAIEngine() = default;
    virtual bool init(const std::string& model_path, const std::string& label_path = "") = 0;
    virtual bool infer(image_buffer_t& img, object_detect_result_list& results) = 0;
    virtual const char* get_label_name(int cls_id) = 0;
    virtual void release() = 0;
};
```

include/hardware/IGpuRenderer.h

```h
#pragma once
#include "image_utils.h"
#include "yolov8.h"
#include "postprocess.h"

class IGpuRenderer {
public:
    virtual ~IGpuRenderer() = default;
    virtual void draw_detections(image_buffer_t& img, const object_detect_result_list& results) = 0;
};
```

include/hardware/IImageProcessor.h

```h
#pragma once
#include <cstddef>
#include "image_utils.h"

class IImageProcessor {
public:
    virtual ~IImageProcessor() = default;
    virtual bool resize_and_convert(const image_buffer_t& src, image_buffer_t& dst, int target_w, int target_h) = 0;
    virtual bool convert_letterbox(image_buffer_t* src_img, image_buffer_t* dst_img, letterbox_t* letterbox, char color = 114) = 0;
};
```

include/hardware/IVideoDecoder.h

```h
#pragma once
#include "image_utils.h"

class IVideoDecoder {
public:
    virtual ~IVideoDecoder() = default;
    virtual bool decode_raw_buffer(const unsigned char* data, int width, int height, int channels, image_buffer_t& frame) = 0;
};
```

include/hardware/NpuInferenceEngine.h

```h
#pragma once
#include "hardware/IAIEngine.h"
#include "yolov8.h"
#include "rknn_api.h"
#include <string>
#include <vector>

class NpuInferenceEngine : public IAIEngine {
public:
    NpuInferenceEngine();
    ~NpuInferenceEngine() override;

    bool init(const std::string& model_path, const std::string& label_path = "") override;
    bool infer(image_buffer_t& img, object_detect_result_list& results) override;
    const char* get_label_name(int cls_id) override;
    void release() override;

private:
    std::string find_model_path(const std::string& user_path);
    std::string find_labels_path(const std::string& user_path);
    void load_labels(const std::string& path);

    rknn_app_context_t app_ctx_;
    bool is_initialized_;
    std::vector<std::string> labels_;
};
```

include/hardware/RgaProcessor.h

```h
#pragma once
#include <cstddef>
#include <stddef.h>
#include "hardware/IImageProcessor.h"
#include "im2d.h"
#include "rga.h"

class RgaProcessor : public IImageProcessor {
public:
    RgaProcessor() = default;
    ~RgaProcessor() override = default;

    bool resize_and_convert(const image_buffer_t& src, image_buffer_t& dst, int target_w, int target_h) override;
    bool convert_letterbox(image_buffer_t* src_img, image_buffer_t* dst_img, letterbox_t* letterbox, char color = 114) override;
};
```

include/hardware/VpuDecoder.h

```h
#pragma once
#include "hardware/IVideoDecoder.h"
#include "rk_mpi.h"
#include "rk_mpi_cmd.h"
#include "mpp_buffer.h"
#include "mpp_frame.h"
#include "mpp_packet.h"
#include "mpp_err.h"

#include <vector>
#include <mutex>
#include <cstdint>
#include <cstddef>

class VpuDecoder : public IVideoDecoder {
public:
    VpuDecoder();
    ~VpuDecoder() override;

    bool decode_raw_buffer(const unsigned char* data, int width, int height, int channels, image_buffer_t& frame) override;
    bool feed_h264_packet(const unsigned char* packet_data, size_t packet_size, uint64_t frame_idx = 0, int64_t pts_ms = 0);
    bool get_latest_frame(std::vector<unsigned char>& out_buffer, image_buffer_t& frame, uint64_t& out_frame_idx, int64_t& out_pts_ms);

private:
    bool init_mpp();
    void release_mpp();
    bool decode_h264_packet(const unsigned char* packet_data, size_t packet_size, image_buffer_t& frame, uint64_t frame_idx = 0, int64_t pts_ms = 0);
    void drain_frames(bool& got_new_frame, uint64_t frame_idx = 0, int64_t pts_ms = 0);

    void* mpp_handle_;
    MppCtx ctx_;
    MppApi* mpi_;
    MppBufferGroup frm_grp_;
    MppPacket packet_;
    bool is_mpp_inited_;

    std::mutex frame_mutex_;
    std::vector<unsigned char> last_nv12_frame_;
    int last_width_;
    int last_height_;
    int last_hor_stride_;
    int last_ver_stride_;
    int last_fd_;
    uint64_t last_frame_idx_;
    int64_t last_pts_ms_;

    MPP_RET (*p_mpp_create)(MppCtx *, MppApi **);
    MPP_RET (*p_mpp_init)(MppCtx, MppCtxType, MppCodingType);
    MPP_RET (*p_mpp_destroy)(MppCtx);
    MPP_RET (*p_mpp_packet_init)(MppPacket *, void *, size_t);
    MPP_RET (*p_mpp_packet_deinit)(MppPacket *);
    void (*p_mpp_packet_set_data)(MppPacket, void *);
    void (*p_mpp_packet_set_size)(MppPacket, size_t);
    void (*p_mpp_packet_set_pos)(MppPacket, void *);
    void (*p_mpp_packet_set_length)(MppPacket, size_t);
    MPP_RET (*p_mpp_frame_init)(MppFrame *);
    MPP_RET (*p_mpp_frame_deinit)(MppFrame *);
    RK_U32 (*p_mpp_frame_get_info_change)(MppFrame);
    RK_U32 (*p_mpp_frame_get_errinfo)(MppFrame);
    RK_U32 (*p_mpp_frame_get_discard)(MppFrame);
    MppBuffer (*p_mpp_frame_get_buffer)(MppFrame);
    RK_U32 (*p_mpp_frame_get_width)(MppFrame);
    RK_U32 (*p_mpp_frame_get_height)(MppFrame);
    RK_U32 (*p_mpp_frame_get_hor_stride)(MppFrame);
    RK_U32 (*p_mpp_frame_get_ver_stride)(MppFrame);
    RK_U32 (*p_mpp_frame_get_buf_size)(MppFrame);
    MppFrameFormat (*p_mpp_frame_get_fmt)(MppFrame);
    void* (*p_mpp_buffer_get_ptr_with_caller)(MppBuffer, const char *);
    int (*p_mpp_buffer_get_fd_with_caller)(MppBuffer, const char *);
    size_t (*p_mpp_buffer_get_size_with_caller)(MppBuffer, const char *);
    MPP_RET (*p_mpp_buffer_group_get)(MppBufferGroup *, MppBufferType, MppBufferMode, const char *, const char *);
    MPP_RET (*p_mpp_buffer_group_limit_config)(MppBufferGroup, size_t, RK_S32);
    MPP_RET (*p_mpp_buffer_group_put)(MppBufferGroup);
    MPP_RET (*p_mpp_buffer_group_clear)(MppBufferGroup);
};
```

include/consts.h

```h
#ifndef CONSTS_H
#define CONSTS_H

#define LABEL_PATH       "model/coco_80_labels_list.txt"
#define MODEL_PATH       "model/yolov8.rknn"
#define MPP_LIB_NAME     "librockchip_mpp.so"

#endif
```

include/detect.h

```h
#ifndef DETECT_H
#define DETECT_H

#ifdef __cplusplus
extern "C" {
#endif

int push_video_packet(const unsigned char* packet_data, int packet_size, unsigned long long frame_idx, long long pts_ms);

int detect_latest_frame(char* out_buf, int out_buf_size, unsigned long long* out_frame_idx, long long* out_pts_ms);

int detect_file_for_cli(const char* image_path, const char* out_json_path, const char* out_image_path);

#ifdef __cplusplus
}
#endif

#endif
```

src/hardware/GpuRenderer.cc

```c
#include "hardware/GpuRenderer.h"
#include "utils/image_drawing.h"
#include <cstdio>

void GpuRenderer::draw_detections(image_buffer_t& img, const object_detect_result_list& results) {
    if (!img.virt_addr) return;
    char text[256];
    for (int i = 0; i < results.count; i++) {
        const object_detect_result& det = results.results[i];
        int x1 = det.box.left;
        int y1 = det.box.top;
        int x2 = det.box.right;
        int y2 = det.box.bottom;

        draw_rectangle(&img, x1, y1, x2 - x1, y2 - y1, COLOR_GREEN, 3);
        const char* label = coco_cls_to_name(det.cls_id);
        snprintf(text, sizeof(text), "%s %.1f%%", (label ? label : "object"), det.prop * 100);
        draw_text(&img, text, x1, y1 - 20, COLOR_RED, 10);
    }
}
```

src/hardware/NpuInferenceEngine.cc

```c
#include "hardware/NpuInferenceEngine.h"
#include "hardware/RgaProcessor.h"
#include "consts.h"
#include "file_utils.h"
#include "image_utils.h"
#include "yolov8.h"
#include "postprocess.h"
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <unistd.h>
#include <fstream>
#include <vector>

NpuInferenceEngine::NpuInferenceEngine() : is_initialized_(false) {
    memset(&app_ctx_, 0, sizeof(rknn_app_context_t));
}

NpuInferenceEngine::~NpuInferenceEngine() {
    release();
}

std::string NpuInferenceEngine::find_model_path(const std::string& user_path) {
    if (!user_path.empty() && access(user_path.c_str(), R_OK) == 0) {
        return user_path;
    }
    return MODEL_PATH;
}

std::string NpuInferenceEngine::find_labels_path(const std::string& user_path) {
    if (!user_path.empty() && access(user_path.c_str(), R_OK) == 0) {
        return user_path;
    }
    return LABEL_PATH;
}

void NpuInferenceEngine::load_labels(const std::string& path) {
    labels_.clear();
    std::string resolved = find_labels_path(path);
    if (resolved.empty()) {
        printf("[NpuEngine] Using built-in COCO 80 labels.\n");
        return;
    }

    std::ifstream file(resolved);
    if (!file.is_open()) {
        printf("[NpuEngine] Could not open label file %s, using default labels.\n", resolved.c_str());
        return;
    }

    std::string line;
    while (std::getline(file, line)) {
        while (!line.empty() && (line.back() == '\r' || line.back() == '\n' || line.back() == ' ')) {
            line.pop_back();
        }
        if (!line.empty()) {
            labels_.push_back(line);
        }
    }
    printf("[NpuEngine] Loaded %zu labels from: %s\n", labels_.size(), resolved.c_str());
}

bool NpuInferenceEngine::init(const std::string& model_path, const std::string& label_path) {
    if (is_initialized_) {
        return true;
    }

    std::string resolved_model = find_model_path(model_path);
    if (resolved_model.empty()) {
        fprintf(stderr, "[NpuEngine] ERROR: yolov8.rknn model file not found!\n");
        return false;
    }

    printf("[NpuEngine] Initializing RKNN model: %s\n", resolved_model.c_str());
    init_post_process();

    int model_len = 0;
    char *model_buf = nullptr;
    model_len = read_data_from_file(resolved_model.c_str(), &model_buf);
    if (!model_buf || model_len <= 0) {
        fprintf(stderr, "[NpuEngine] ERROR: Failed to read model file!\n");
        return false;
    }

    rknn_context ctx = 0;
    int ret = rknn_init(&ctx, model_buf, model_len, 0, NULL);
    free(model_buf);
    if (ret < 0) {
        fprintf(stderr, "[NpuEngine] ERROR: rknn_init failed (%d)\n", ret);
        return false;
    }

    rknn_input_output_num io_num;
    ret = rknn_query(ctx, RKNN_QUERY_IN_OUT_NUM, &io_num, sizeof(io_num));
    if (ret != RKNN_SUCC) {
        fprintf(stderr, "[NpuEngine] ERROR: rknn_query IO_NUM failed (%d)\n", ret);
        rknn_destroy(ctx);
        return false;
    }

    rknn_tensor_attr input_attrs[io_num.n_input];
    memset(input_attrs, 0, sizeof(input_attrs));
    for (int i = 0; i < io_num.n_input; i++) {
        input_attrs[i].index = i;
        rknn_query(ctx, RKNN_QUERY_INPUT_ATTR, &(input_attrs[i]), sizeof(rknn_tensor_attr));
    }

    rknn_tensor_attr output_attrs[io_num.n_output];
    memset(output_attrs, 0, sizeof(output_attrs));
    for (int i = 0; i < io_num.n_output; i++) {
        output_attrs[i].index = i;
        rknn_query(ctx, RKNN_QUERY_OUTPUT_ATTR, &(output_attrs[i]), sizeof(rknn_tensor_attr));
    }

    app_ctx_.rknn_ctx = ctx;
    app_ctx_.io_num = io_num;
    app_ctx_.input_attrs = (rknn_tensor_attr *)malloc(io_num.n_input * sizeof(rknn_tensor_attr));
    memcpy(app_ctx_.input_attrs, input_attrs, io_num.n_input * sizeof(rknn_tensor_attr));
    app_ctx_.output_attrs = (rknn_tensor_attr *)malloc(io_num.n_output * sizeof(rknn_tensor_attr));
    memcpy(app_ctx_.output_attrs, output_attrs, io_num.n_output * sizeof(rknn_tensor_attr));

    if (output_attrs[0].type == RKNN_TENSOR_INT8 || output_attrs[0].qnt_type == RKNN_TENSOR_QNT_AFFINE_ASYMMETRIC) {
        app_ctx_.is_quant = true;
    } else {
        app_ctx_.is_quant = false;
    }

    if (input_attrs[0].fmt == RKNN_TENSOR_NCHW) {
        app_ctx_.model_channel = input_attrs[0].dims[1];
        app_ctx_.model_height = input_attrs[0].dims[2];
        app_ctx_.model_width = input_attrs[0].dims[3];
    } else {
        app_ctx_.model_height = input_attrs[0].dims[1];
        app_ctx_.model_width = input_attrs[0].dims[2];
        app_ctx_.model_channel = input_attrs[0].dims[3];
    }

    rknn_set_core_mask(app_ctx_.rknn_ctx, RKNN_NPU_CORE_0_1);

    load_labels(label_path);
    is_initialized_ = true;
    printf("[NpuEngine] Rockchip NPU (RKNN) AI Engine Ready. (model: %dx%dx%d, quant: %d)\n",
           app_ctx_.model_width, app_ctx_.model_height, app_ctx_.model_channel, (int)app_ctx_.is_quant);
    return true;
}

bool NpuInferenceEngine::infer(image_buffer_t& img, object_detect_result_list& results) {
    if (!is_initialized_ || !img.virt_addr) {
        return false;
    }

    static RgaProcessor s_rga_processor;
    image_buffer_t dst_img;
    memset(&dst_img, 0, sizeof(image_buffer_t));
    dst_img.width = app_ctx_.model_width;
    dst_img.height = app_ctx_.model_height;
    dst_img.format = IMAGE_FORMAT_RGB888;
    dst_img.size = app_ctx_.model_width * app_ctx_.model_height * 3;

    std::vector<unsigned char> input_buf(dst_img.size);
    dst_img.virt_addr = input_buf.data();

    letterbox_t letter_box;
    memset(&letter_box, 0, sizeof(letterbox_t));

    bool rga_ok = s_rga_processor.convert_letterbox(&img, &dst_img, &letter_box, 114);
    if (!rga_ok) {
        return false;
    }

    rknn_input inputs[1];
    memset(inputs, 0, sizeof(inputs));
    inputs[0].index = 0;
    inputs[0].type = RKNN_TENSOR_UINT8;
    inputs[0].fmt = RKNN_TENSOR_NHWC;
    inputs[0].size = dst_img.size;
    inputs[0].buf = input_buf.data();

    int ret = rknn_inputs_set(app_ctx_.rknn_ctx, app_ctx_.io_num.n_input, inputs);
    if (ret < 0) {
        return false;
    }

    ret = rknn_run(app_ctx_.rknn_ctx, nullptr);
    if (ret < 0) {
        return false;
    }

    rknn_output outputs[app_ctx_.io_num.n_output];
    memset(outputs, 0, sizeof(outputs));
    for (int i = 0; i < app_ctx_.io_num.n_output; i++) {
        outputs[i].index = i;
        outputs[i].want_float = (!app_ctx_.is_quant);
    }

    ret = rknn_outputs_get(app_ctx_.rknn_ctx, app_ctx_.io_num.n_output, outputs, NULL);
    if (ret < 0) {
        return false;
    }

    post_process(&app_ctx_, outputs, &letter_box, 0.25f, 0.45f, &results);

    rknn_outputs_release(app_ctx_.rknn_ctx, app_ctx_.io_num.n_output, outputs);
    return true;
}

const char* NpuInferenceEngine::get_label_name(int cls_id) {
    if (cls_id >= 0 && cls_id < (int)labels_.size()) {
        return labels_[cls_id].c_str();
    }
    const char* name = coco_cls_to_name(cls_id);
    if (name && strcmp(name, "null") != 0) {
        return name;
    }
    return "object";
}

void NpuInferenceEngine::release() {
    if (is_initialized_) {
        deinit_post_process();
        if (app_ctx_.input_attrs != NULL) {
            free(app_ctx_.input_attrs);
            app_ctx_.input_attrs = NULL;
        }
        if (app_ctx_.output_attrs != NULL) {
            free(app_ctx_.output_attrs);
            app_ctx_.output_attrs = NULL;
        }
        if (app_ctx_.rknn_ctx != 0) {
            rknn_destroy(app_ctx_.rknn_ctx);
            app_ctx_.rknn_ctx = 0;
        }
        is_initialized_ = false;
        labels_.clear();
        printf("[NpuEngine] NPU RKNN resources released.\n");
    }
}
```

src/hardware/RgaProcessor.cc

```c
#include "hardware/RgaProcessor.h"
#include "im2d.h"
#include "rga.h"
#include <cstdio>
#include <cstring>
#include <cmath>

static int get_rga_format(image_format_t fmt) {
    switch (fmt) {
    case IMAGE_FORMAT_RGB888:
        return RK_FORMAT_RGB_888;
    case IMAGE_FORMAT_RGBA8888:
        return RK_FORMAT_RGBA_8888;
    case IMAGE_FORMAT_YUV420SP_NV12:
        return RK_FORMAT_YCbCr_420_SP;
    case IMAGE_FORMAT_YUV420SP_NV21:
        return RK_FORMAT_YCrCb_420_SP;
    default:
        return RK_FORMAT_YCbCr_420_SP;
    }
}

bool RgaProcessor::resize_and_convert(const image_buffer_t& src, image_buffer_t& dst, int target_w, int target_h) {
    if (!src.virt_addr || !dst.virt_addr) {
        return false;
    }

    int src_w_stride = src.width_stride > 0 ? src.width_stride : src.width;
    int src_h_stride = src.height_stride > 0 ? src.height_stride : src.height;
    int src_fmt = get_rga_format(src.format);
    int dst_fmt = get_rga_format(dst.format);

    rga_buffer_t rga_src = wrapbuffer_virtualaddr(src.virt_addr, src.width, src.height, src_fmt, src_w_stride, src_h_stride);
    rga_buffer_t rga_dst = wrapbuffer_virtualaddr(dst.virt_addr, target_w, target_h, dst_fmt, target_w, target_h);

    int ret = imresize(rga_src, rga_dst);
    return (ret == IM_STATUS_SUCCESS || ret == IM_STATUS_NOERROR);
}

bool RgaProcessor::convert_letterbox(image_buffer_t* src_img, image_buffer_t* dst_img, letterbox_t* letterbox, char color) {
    if (!src_img || !dst_img || !src_img->virt_addr || !dst_img->virt_addr) {
        return false;
    }

    int src_w = src_img->width;
    int src_h = src_img->height;
    int dst_w = dst_img->width;
    int dst_h = dst_img->height;

    float scale = 1.0f;
    float scale_w = (float)dst_w / (float)src_w;
    float scale_h = (float)dst_h / (float)src_h;
    int resize_w = dst_w;
    int resize_h = dst_h;

    if (scale_w < scale_h) {
        scale = scale_w;
        resize_h = (int)roundf((float)src_h * scale);
    } else {
        scale = scale_h;
        resize_w = (int)roundf((float)src_w * scale);
    }

    if (resize_w % 2 != 0) resize_w -= 1;
    if (resize_h % 2 != 0) resize_h -= 1;

    int pad_w = dst_w - resize_w;
    int pad_h = dst_h - resize_h;
    int left_pad = (pad_w / 2) & ~1;
    int top_pad  = (pad_h / 2) & ~1;

    if (letterbox) {
        letterbox->scale = scale;
        letterbox->x_pad = left_pad;
        letterbox->y_pad = top_pad;
    }

    int src_w_stride = src_img->width_stride > 0 ? src_img->width_stride : src_img->width;
    int src_h_stride = src_img->height_stride > 0 ? src_img->height_stride : src_img->height;
    int src_fmt = get_rga_format(src_img->format);
    int dst_fmt = get_rga_format(dst_img->format);

    rga_buffer_t rga_src = wrapbuffer_virtualaddr(src_img->virt_addr, src_w, src_h, src_fmt, src_w_stride, src_h_stride);
    rga_buffer_t rga_dst = wrapbuffer_virtualaddr(dst_img->virt_addr, dst_w, dst_h, dst_fmt, dst_w, dst_h);

    im_rect full_dst_rect = {0, 0, dst_w, dst_h};
    int imcolor = 0;
    char* p_col = (char*)&imcolor;
    p_col[0] = color;
    p_col[1] = color;
    p_col[2] = color;
    p_col[3] = color;
    imfill(rga_dst, full_dst_rect, imcolor);

    im_rect srect = {0, 0, src_w, src_h};
    im_rect drect = {left_pad, top_pad, resize_w, resize_h};
    im_rect prect = {0, 0, 0, 0};
    rga_buffer_t pat;
    memset(&pat, 0, sizeof(pat));

    IM_STATUS status = improcess(rga_src, rga_dst, pat, srect, drect, prect, 0);
    return (status == IM_STATUS_SUCCESS || status == IM_STATUS_NOERROR);
}
```

src/hardware/VpuDecoder.cc

```c
#include "hardware/VpuDecoder.h"
#include "consts.h"
#include "utils/image_utils.h"
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <dlfcn.h>
#include <unistd.h>
#include <vector>

VpuDecoder::VpuDecoder()
    : mpp_handle_(nullptr),
      ctx_(nullptr),
      mpi_(nullptr),
      frm_grp_(nullptr),
      packet_(nullptr),
      is_mpp_inited_(false),
      last_width_(0),
      last_height_(0),
      last_hor_stride_(0),
      last_ver_stride_(0),
      last_fd_(-1),
      last_frame_idx_(0),
      last_pts_ms_(0) {
}

VpuDecoder::~VpuDecoder() {
    release_mpp();
}

bool VpuDecoder::init_mpp() {
    if (is_mpp_inited_) {
        return true;
    }

    mpp_handle_ = dlopen(MPP_LIB_NAME, RTLD_LAZY | RTLD_GLOBAL);
    if (!mpp_handle_) {
        mpp_handle_ = dlopen("librockchip_mpp.so.1", RTLD_LAZY | RTLD_GLOBAL);
    }

    if (!mpp_handle_) {
        printf("[VpuDecoder] Rockchip MPP library not found on board.\n");
        return false;
    }

    p_mpp_create = (MPP_RET (*)(MppCtx *, MppApi **))dlsym(mpp_handle_, "mpp_create");
    p_mpp_init = (MPP_RET (*)(MppCtx, MppCtxType, MppCodingType))dlsym(mpp_handle_, "mpp_init");
    p_mpp_destroy = (MPP_RET (*)(MppCtx))dlsym(mpp_handle_, "mpp_destroy");
    p_mpp_packet_init = (MPP_RET (*)(MppPacket *, void *, size_t))dlsym(mpp_handle_, "mpp_packet_init");
    p_mpp_packet_deinit = (MPP_RET (*)(MppPacket *))dlsym(mpp_handle_, "mpp_packet_deinit");
    p_mpp_packet_set_data = (void (*)(MppPacket, void *))dlsym(mpp_handle_, "mpp_packet_set_data");
    p_mpp_packet_set_size = (void (*)(MppPacket, size_t))dlsym(mpp_handle_, "mpp_packet_set_size");
    p_mpp_packet_set_pos = (void (*)(MppPacket, void *))dlsym(mpp_handle_, "mpp_packet_set_pos");
    p_mpp_packet_set_length = (void (*)(MppPacket, size_t))dlsym(mpp_handle_, "mpp_packet_set_length");
    p_mpp_frame_init = (MPP_RET (*)(MppFrame *))dlsym(mpp_handle_, "mpp_frame_init");
    p_mpp_frame_deinit = (MPP_RET (*)(MppFrame *))dlsym(mpp_handle_, "mpp_frame_deinit");
    p_mpp_frame_get_info_change = (RK_U32 (*)(MppFrame))dlsym(mpp_handle_, "mpp_frame_get_info_change");
    p_mpp_frame_get_errinfo = (RK_U32 (*)(MppFrame))dlsym(mpp_handle_, "mpp_frame_get_errinfo");
    p_mpp_frame_get_discard = (RK_U32 (*)(MppFrame))dlsym(mpp_handle_, "mpp_frame_get_discard");
    p_mpp_frame_get_buffer = (MppBuffer (*)(MppFrame))dlsym(mpp_handle_, "mpp_frame_get_buffer");
    p_mpp_frame_get_width = (RK_U32 (*)(MppFrame))dlsym(mpp_handle_, "mpp_frame_get_width");
    p_mpp_frame_get_height = (RK_U32 (*)(MppFrame))dlsym(mpp_handle_, "mpp_frame_get_height");
    p_mpp_frame_get_hor_stride = (RK_U32 (*)(MppFrame))dlsym(mpp_handle_, "mpp_frame_get_hor_stride");
    p_mpp_frame_get_ver_stride = (RK_U32 (*)(MppFrame))dlsym(mpp_handle_, "mpp_frame_get_ver_stride");
    p_mpp_frame_get_buf_size = (RK_U32 (*)(MppFrame))dlsym(mpp_handle_, "mpp_frame_get_buf_size");
    p_mpp_frame_get_fmt = (MppFrameFormat (*)(MppFrame))dlsym(mpp_handle_, "mpp_frame_get_fmt");

    p_mpp_buffer_get_ptr_with_caller = (void* (*)(MppBuffer, const char *))dlsym(mpp_handle_, "mpp_buffer_get_ptr_with_caller");
    if (!p_mpp_buffer_get_ptr_with_caller) {
        p_mpp_buffer_get_ptr_with_caller = (void* (*)(MppBuffer, const char *))dlsym(mpp_handle_, "mpp_buffer_get_ptr");
    }

    p_mpp_buffer_get_fd_with_caller = (int (*)(MppBuffer, const char *))dlsym(mpp_handle_, "mpp_buffer_get_fd_with_caller");
    if (!p_mpp_buffer_get_fd_with_caller) {
        p_mpp_buffer_get_fd_with_caller = (int (*)(MppBuffer, const char *))dlsym(mpp_handle_, "mpp_buffer_get_fd");
    }

    p_mpp_buffer_get_size_with_caller = (size_t (*)(MppBuffer, const char *))dlsym(mpp_handle_, "mpp_buffer_get_size_with_caller");
    if (!p_mpp_buffer_get_size_with_caller) {
        p_mpp_buffer_get_size_with_caller = (size_t (*)(MppBuffer, const char *))dlsym(mpp_handle_, "mpp_buffer_get_size");
    }

    p_mpp_buffer_group_get = (MPP_RET (*)(MppBufferGroup *, MppBufferType, MppBufferMode, const char *, const char *))dlsym(mpp_handle_, "mpp_buffer_group_get");
    p_mpp_buffer_group_limit_config = (MPP_RET (*)(MppBufferGroup, size_t, RK_S32))dlsym(mpp_handle_, "mpp_buffer_group_limit_config");
    p_mpp_buffer_group_put = (MPP_RET (*)(MppBufferGroup))dlsym(mpp_handle_, "mpp_buffer_group_put");
    p_mpp_buffer_group_clear = (MPP_RET (*)(MppBufferGroup))dlsym(mpp_handle_, "mpp_buffer_group_clear");

    printf("[VpuDecoder] Symbols: get_ptr=%p, get_fd=%p, get_size=%p, get_fmt=%p\n",
           p_mpp_buffer_get_ptr_with_caller, p_mpp_buffer_get_fd_with_caller, p_mpp_buffer_get_size_with_caller, p_mpp_frame_get_fmt);

    if (!p_mpp_create || !p_mpp_init || !p_mpp_destroy || !p_mpp_packet_init) {
        printf("[VpuDecoder] Failed to resolve required MPP symbols.\n");
        dlclose(mpp_handle_);
        mpp_handle_ = nullptr;
        return false;
    }

    MPP_RET ret = p_mpp_create(&ctx_, &mpi_);
    if (ret != MPP_OK || !ctx_ || !mpi_) {
        printf("[VpuDecoder] mpp_create failed (%d)\n", ret);
        return false;
    }

    ret = p_mpp_init(ctx_, MPP_CTX_DEC, MPP_VIDEO_CodingAVC);
    if (ret != MPP_OK) {
        printf("[VpuDecoder] mpp_init DEC AVC failed (%d)\n", ret);
        p_mpp_destroy(ctx_);
        ctx_ = nullptr;
        mpi_ = nullptr;
        return false;
    }

    RK_U32 need_split = 1;
    mpi_->control(ctx_, MPP_DEC_SET_PARSER_SPLIT_MODE, &need_split);

    MppFrameFormat out_fmt = MPP_FMT_YUV420SP;
    int set_fmt_ret = mpi_->control(ctx_, MPP_DEC_SET_OUTPUT_FORMAT, &out_fmt);
    printf("[VpuDecoder] MPP_DEC_SET_OUTPUT_FORMAT (MPP_FMT_YUV420SP) ret=%d\n", set_fmt_ret);

    ret = p_mpp_packet_init(&packet_, nullptr, 0);
    if (ret != MPP_OK) {
        printf("[VpuDecoder] mpp_packet_init failed (%d)\n", ret);
        return false;
    }

    frm_grp_ = nullptr;
    is_mpp_inited_ = true;
    printf("[VpuDecoder] Rockchip VPU (MPP H.264) hardware decoder initialized successfully (CMD_BASE=0x%08x).\n", MPP_DEC_CMD_BASE);
    return true;
}

void VpuDecoder::release_mpp() {
    if (packet_ && p_mpp_packet_deinit) {
        p_mpp_packet_deinit(&packet_);
        packet_ = nullptr;
    }
    if (frm_grp_ && p_mpp_buffer_group_put) {
        p_mpp_buffer_group_put(frm_grp_);
        frm_grp_ = nullptr;
    }
    if (is_mpp_inited_ && ctx_) {
        if (p_mpp_destroy) {
            p_mpp_destroy(ctx_);
        }
        ctx_ = nullptr;
        mpi_ = nullptr;
        is_mpp_inited_ = false;
    }
    if (mpp_handle_) {
        dlclose(mpp_handle_);
        mpp_handle_ = nullptr;
    }
}

void VpuDecoder::drain_frames(bool& got_new_frame, uint64_t frame_idx, int64_t pts_ms) {
    if (!is_mpp_inited_ || !mpi_ || !ctx_) {
        return;
    }
    while (true) {
        MppFrame mpp_frame = nullptr;
        MPP_RET ret = mpi_->decode_get_frame(ctx_, &mpp_frame);
        if (ret != MPP_OK || !mpp_frame) {
            break;
        }

        uint32_t is_info_change = p_mpp_frame_get_info_change ? p_mpp_frame_get_info_change(mpp_frame) : 0;
        uint32_t errinfo = p_mpp_frame_get_errinfo ? p_mpp_frame_get_errinfo(mpp_frame) : 0;
        uint32_t discard = p_mpp_frame_get_discard ? p_mpp_frame_get_discard(mpp_frame) : 0;
        MppBuffer buffer = p_mpp_frame_get_buffer ? p_mpp_frame_get_buffer(mpp_frame) : nullptr;
        uint32_t width = p_mpp_frame_get_width ? p_mpp_frame_get_width(mpp_frame) : 0;
        uint32_t height = p_mpp_frame_get_height ? p_mpp_frame_get_height(mpp_frame) : 0;
        uint32_t hor_stride = p_mpp_frame_get_hor_stride ? p_mpp_frame_get_hor_stride(mpp_frame) : width;
        uint32_t ver_stride = p_mpp_frame_get_ver_stride ? p_mpp_frame_get_ver_stride(mpp_frame) : height;

        static int s_frame_poll_count = 0;
        s_frame_poll_count++;

        if (is_info_change) {
            size_t buf_size = p_mpp_frame_get_buf_size ? p_mpp_frame_get_buf_size(mpp_frame) : 0;
            if (buf_size == 0) {
                buf_size = hor_stride * ver_stride * 3 / 2;
            }
            printf("[VpuDecoder] Info change event #%d: %ux%u (stride: %ux%u, buf_size: %zu)\n",
                   s_frame_poll_count, width, height, hor_stride, ver_stride, buf_size);

            if (frm_grp_ == nullptr) {
                if (p_mpp_buffer_group_get) {
                    ret = p_mpp_buffer_group_get(&frm_grp_, MPP_BUFFER_TYPE_DRM, MPP_BUFFER_INTERNAL, NULL, NULL);
                    if (ret != MPP_OK || !frm_grp_) {
                        ret = p_mpp_buffer_group_get(&frm_grp_, MPP_BUFFER_TYPE_DMA_HEAP, MPP_BUFFER_INTERNAL, NULL, NULL);
                    }
                    if (ret != MPP_OK || !frm_grp_) {
                        ret = p_mpp_buffer_group_get(&frm_grp_, MPP_BUFFER_TYPE_ION, MPP_BUFFER_INTERNAL, NULL, NULL);
                    }
                }
                int r_ext = mpi_->control(ctx_, MPP_DEC_SET_EXT_BUF_GROUP, frm_grp_);
                printf("[VpuDecoder] Created frm_grp=%p, SET_EXT_BUF_GROUP (0x%08x) ret=%d\n",
                       frm_grp_, MPP_DEC_SET_EXT_BUF_GROUP, r_ext);
            } else {
                if (p_mpp_buffer_group_clear) {
                    p_mpp_buffer_group_clear(frm_grp_);
                }
            }

            if (frm_grp_ && p_mpp_buffer_group_limit_config) {
                p_mpp_buffer_group_limit_config(frm_grp_, buf_size, 24);
            }

            int cr = mpi_->control(ctx_, MPP_DEC_SET_INFO_CHANGE_READY, nullptr);
            printf("[VpuDecoder] MPP_DEC_SET_INFO_CHANGE_READY (0x%08x) ret=%d\n", MPP_DEC_SET_INFO_CHANGE_READY, cr);

            if (p_mpp_frame_deinit) {
                p_mpp_frame_deinit(&mpp_frame);
            }
            continue;
        }

        if (errinfo) {
            static int s_err_cnt = 0;
            if (s_err_cnt++ % 30 == 0) {
                printf("[VpuDecoder] Frame #%d errinfo=0x%x\n", s_frame_poll_count, errinfo);
            }
        }

        if (discard) {
            if (p_mpp_frame_deinit) {
                p_mpp_frame_deinit(&mpp_frame);
            }
            continue;
        }

        if (buffer && width > 0 && height > 0) {
            void* ptr = p_mpp_buffer_get_ptr_with_caller ? p_mpp_buffer_get_ptr_with_caller(buffer, "drain_frames") : nullptr;
            size_t buf_size = p_mpp_buffer_get_size_with_caller ? p_mpp_buffer_get_size_with_caller(buffer, "drain_frames") : 0;
            int fd = p_mpp_buffer_get_fd_with_caller ? p_mpp_buffer_get_fd_with_caller(buffer, "drain_frames") : -1;
            if (buf_size == 0) {
                buf_size = hor_stride * ver_stride * 3 / 2;
            }

            if (ptr && buf_size > 0) {
                {
                    std::lock_guard<std::mutex> lock(frame_mutex_);
                    last_nv12_frame_.assign((unsigned char*)ptr, (unsigned char*)ptr + buf_size);
                    last_width_ = (int)width;
                    last_height_ = (int)height;
                    last_hor_stride_ = (int)hor_stride;
                    last_ver_stride_ = (int)ver_stride;
                    last_fd_ = fd;
                    last_frame_idx_ = frame_idx;
                    last_pts_ms_ = pts_ms;
                }
                got_new_frame = true;

                static bool s_logged_first = false;
                if (!s_logged_first) {
                    MppFrameFormat fmt = p_mpp_frame_get_fmt ? p_mpp_frame_get_fmt(mpp_frame) : MPP_FMT_YUV420SP;
                    printf("[VpuDecoder] SUCCESS: First video frame decoded: %dx%d (stride: %dx%d, size: %zu, fd: %d, fmt=0x%08x)\n",
                           last_width_, last_height_, last_hor_stride_, last_ver_stride_, buf_size, fd, (unsigned int)fmt);
                    fflush(stdout);
                    s_logged_first = true;
                }
            } else {
                static int s_nobuf_cnt = 0;
                if (s_nobuf_cnt++ % 30 == 0) {
                    printf("[VpuDecoder] Frame #%d buffer valid but ptr=%p, fd=%d, size=%zu\n",
                           s_frame_poll_count, ptr, fd, buf_size);
                    fflush(stdout);
                }
            }
        }

        if (p_mpp_frame_deinit) {
            p_mpp_frame_deinit(&mpp_frame);
        }
    }
}

bool VpuDecoder::decode_h264_packet(const unsigned char* packet_data, size_t packet_size, image_buffer_t& frame, uint64_t frame_idx, int64_t pts_ms) {
    if (!is_mpp_inited_) {
        if (!init_mpp()) {
            return false;
        }
    }

    if (!packet_data || packet_size == 0 || !mpi_ || !packet_) {
        return false;
    }

    static std::vector<unsigned char> s_feed_buf;
    const unsigned char* feed_ptr = packet_data;
    size_t feed_size = packet_size;

    if (packet_size >= 4) {
        bool has_start_code = (packet_data[0] == 0 && packet_data[1] == 0 && packet_data[2] == 0 && packet_data[3] == 1) ||
                              (packet_data[0] == 0 && packet_data[1] == 0 && packet_data[2] == 1);
        if (!has_start_code) {
            s_feed_buf.clear();
            s_feed_buf.reserve(packet_size + 4);
            s_feed_buf.push_back(0x00);
            s_feed_buf.push_back(0x00);
            s_feed_buf.push_back(0x00);
            s_feed_buf.push_back(0x01);
            s_feed_buf.insert(s_feed_buf.end(), packet_data, packet_data + packet_size);
            feed_ptr = s_feed_buf.data();
            feed_size = s_feed_buf.size();
        }
    }

    if (p_mpp_packet_set_data) p_mpp_packet_set_data(packet_, const_cast<unsigned char*>(feed_ptr));
    if (p_mpp_packet_set_size) p_mpp_packet_set_size(packet_, feed_size);
    if (p_mpp_packet_set_pos) p_mpp_packet_set_pos(packet_, const_cast<unsigned char*>(feed_ptr));
    if (p_mpp_packet_set_length) p_mpp_packet_set_length(packet_, feed_size);

    bool got_new_frame = false;

    drain_frames(got_new_frame, frame_idx, pts_ms);

    int put_ret = -1;
    for (int retry = 0; retry < 5; retry++) {
        put_ret = mpi_->decode_put_packet(ctx_, packet_);
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
            printf("[VpuDecoder] mpi_->decode_put_packet failed (%d, size=%zu)\n", put_ret, feed_size);
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

    std::lock_guard<std::mutex> lock(frame_mutex_);
    if (got_new_frame && !last_nv12_frame_.empty() && last_width_ > 0 && last_height_ > 0) {
        memset(&frame, 0, sizeof(image_buffer_t));
        frame.width = last_width_;
        frame.height = last_height_;
        frame.width_stride = last_hor_stride_ > 0 ? last_hor_stride_ : last_width_;
        frame.height_stride = last_ver_stride_ > 0 ? last_ver_stride_ : last_height_;
        frame.format = IMAGE_FORMAT_YUV420SP_NV12;
        frame.virt_addr = last_nv12_frame_.data();
        frame.fd = -1;
        frame.size = (int)last_nv12_frame_.size();
        return true;
    }

    return false;
}

bool VpuDecoder::feed_h264_packet(const unsigned char* packet_data, size_t packet_size, uint64_t frame_idx, int64_t pts_ms) {
    if (!is_mpp_inited_) {
        if (!init_mpp()) {
            return false;
        }
    }

    if (!packet_data || packet_size == 0 || !mpi_ || !packet_) {
        return false;
    }

    static std::vector<unsigned char> s_feed_buf;
    const unsigned char* feed_ptr = packet_data;
    size_t feed_size = packet_size;

    if (packet_size >= 4) {
        bool has_start_code = (packet_data[0] == 0 && packet_data[1] == 0 && packet_data[2] == 0 && packet_data[3] == 1) ||
                              (packet_data[0] == 0 && packet_data[1] == 0 && packet_data[2] == 1);
        if (!has_start_code) {
            s_feed_buf.clear();
            s_feed_buf.reserve(packet_size + 4);
            s_feed_buf.push_back(0x00);
            s_feed_buf.push_back(0x00);
            s_feed_buf.push_back(0x00);
            s_feed_buf.push_back(0x01);
            s_feed_buf.insert(s_feed_buf.end(), packet_data, packet_data + packet_size);
            feed_ptr = s_feed_buf.data();
            feed_size = s_feed_buf.size();
        }
    }

    if (p_mpp_packet_set_data) p_mpp_packet_set_data(packet_, const_cast<unsigned char*>(feed_ptr));
    if (p_mpp_packet_set_size) p_mpp_packet_set_size(packet_, feed_size);
    if (p_mpp_packet_set_pos) p_mpp_packet_set_pos(packet_, const_cast<unsigned char*>(feed_ptr));
    if (p_mpp_packet_set_length) p_mpp_packet_set_length(packet_, feed_size);

    bool got_new_frame = false;

    drain_frames(got_new_frame, frame_idx, pts_ms);

    int put_ret = mpi_->decode_put_packet(ctx_, packet_);
    if (put_ret == MPP_ERR_BUFFER_FULL) {
        drain_frames(got_new_frame, frame_idx, pts_ms);
        mpi_->decode_put_packet(ctx_, packet_);
    }

    drain_frames(got_new_frame, frame_idx, pts_ms);

    return true;
}

bool VpuDecoder::get_latest_frame(std::vector<unsigned char>& out_buffer, image_buffer_t& frame, uint64_t& out_frame_idx, int64_t& out_pts_ms) {
    std::lock_guard<std::mutex> lock(frame_mutex_);
    if (last_nv12_frame_.empty() || last_width_ <= 0 || last_height_ <= 0) {
        return false;
    }
    out_buffer = last_nv12_frame_;
    memset(&frame, 0, sizeof(image_buffer_t));
    frame.width = last_width_;
    frame.height = last_height_;
    frame.width_stride = last_hor_stride_ > 0 ? last_hor_stride_ : last_width_;
    frame.height_stride = last_ver_stride_ > 0 ? last_ver_stride_ : last_height_;
    frame.format = IMAGE_FORMAT_YUV420SP_NV12;
    frame.virt_addr = out_buffer.data();
    frame.fd = -1;
    frame.size = (int)out_buffer.size();
    out_frame_idx = last_frame_idx_;
    out_pts_ms = last_pts_ms_;
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
                printf("[VpuDecoder] decode_h264_packet returned false (pkt_size=%zu, inited=%d, has_last_frame=%d)\n",
                       packet_size, (int)is_mpp_inited_, (int)!last_nv12_frame_.empty());
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

src/detect.cpp

```c
#include "detect.h"
#include "hardware/VpuDecoder.h"
#include "hardware/RgaProcessor.h"
#include "hardware/NpuInferenceEngine.h"
#include "hardware/GpuRenderer.h"
#include "image_utils.h"
#include "file_utils.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <memory>
#include <mutex>
#include <string>
#include <vector>

static std::unique_ptr<NpuInferenceEngine> g_npu_engine;
static std::unique_ptr<VpuDecoder> g_vpu_decoder;
static std::unique_ptr<GpuRenderer> g_gpu_renderer;
static std::mutex g_detect_mutex;

static void ensure_engine_initialized() {
    if (!g_npu_engine) {
        g_npu_engine = std::make_unique<NpuInferenceEngine>();
    }
    if (!g_vpu_decoder) {
        g_vpu_decoder = std::make_unique<VpuDecoder>();
    }
    if (!g_gpu_renderer) {
        g_gpu_renderer = std::make_unique<GpuRenderer>();
    }
}

int push_video_packet(const unsigned char* packet_data, int packet_size, unsigned long long frame_idx, long long pts_ms) {
    if (!packet_data || packet_size <= 0) return -1;
    ensure_engine_initialized();
    bool ok = g_vpu_decoder->feed_h264_packet(packet_data, (size_t)packet_size, (uint64_t)frame_idx, (int64_t)pts_ms);
    return ok ? 0 : -1;
}

int detect_latest_frame(char* out_buf, int out_buf_size, unsigned long long* out_frame_idx, long long* out_pts_ms) {
    if (!out_buf || out_buf_size <= 0) return -1;
    ensure_engine_initialized();

    static bool s_auto_inited = false;
    if (!s_auto_inited) {
        if (!g_npu_engine->init("", "")) {
            snprintf(out_buf, out_buf_size, "{\"frame_width\":0,\"frame_height\":0,\"detections\":[]}");
            return (int)strlen(out_buf);
        }
        s_auto_inited = true;
    }

    std::vector<unsigned char> local_nv12;
    image_buffer_t frame;
    uint64_t frame_idx = 0;
    int64_t pts_ms = 0;

    if (!g_vpu_decoder->get_latest_frame(local_nv12, frame, frame_idx, pts_ms)) {
        snprintf(out_buf, out_buf_size, "{\"frame_width\":0,\"frame_height\":0,\"detections\":[]}");
        return (int)strlen(out_buf);
    }

    if (out_frame_idx) *out_frame_idx = frame_idx;
    if (out_pts_ms) *out_pts_ms = pts_ms;

    struct timespec ts_start, ts_end;
    clock_gettime(CLOCK_MONOTONIC, &ts_start);

    object_detect_result_list results;
    memset(&results, 0, sizeof(results));

    if (!g_npu_engine->infer(frame, results)) {
        snprintf(out_buf, out_buf_size, "{\"frame_width\":%d,\"frame_height\":%d,\"detections\":[]}", frame.width, frame.height);
        return (int)strlen(out_buf);
    }

    clock_gettime(CLOCK_MONOTONIC, &ts_end);
    double cost_ms = (ts_end.tv_sec - ts_start.tv_sec) * 1000.0 + (ts_end.tv_nsec - ts_start.tv_nsec) / 1000000.0;

    int written = 0;
    written += snprintf(out_buf + written, out_buf_size - written,
        "{\"frame_width\": %d, \"frame_height\": %d, \"frame_idx\": %llu, \"pts_ms\": %lld, \"detections\": [",
        frame.width, frame.height, (unsigned long long)frame_idx, (long long)pts_ms);

    for (int i = 0; i < results.count; i++) {
        int cls_id = results.results[i].cls_id;
        const char* label = g_npu_engine->get_label_name(cls_id);
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

        written += snprintf(out_buf + written, out_buf_size - written,
            "%s{\"class_id\": %d, \"label\": \"%s\", \"confidence\": %.2f, \"rel_box\": [%.4f, %.4f, %.4f, %.4f], \"box\": [%d, %d, %d, %d]}",
            (i > 0 ? ", " : ""),
            cls_id, label, conf, rx1, ry1, rx2, ry2, x1, y1, x2, y2
        );

        if (written >= out_buf_size - 4) break;
    }

    written += snprintf(out_buf + written, out_buf_size - written, "]}");

    static int s_latest_cnt = 0;
    if (++s_latest_cnt % 90 == 0) {
        printf("[detect_lib] Latest infer #%d (cost=%.2fms, targets=%d, F#%llu, PTS=%lldms)\n",
               s_latest_cnt, cost_ms, results.count, (unsigned long long)frame_idx, (long long)pts_ms);
        fflush(stdout);
    }

    return written;
}

int detect_file_for_cli(const char* image_path, const char* out_json_path, const char* out_image_path) {
    if (!image_path) return -1;

    image_buffer_t img;
    memset(&img, 0, sizeof(image_buffer_t));
    if (read_image(image_path, &img) != 0) {
        fprintf(stderr, "[detect_file_for_cli] Failed to read input image: %s\n", image_path);
        return -1;
    }

    std::lock_guard<std::mutex> lock(g_detect_mutex);
    ensure_engine_initialized();

    static bool s_auto_inited = false;
    if (!s_auto_inited) {
        g_npu_engine->init("", "");
        s_auto_inited = true;
    }

    object_detect_result_list results;
    memset(&results, 0, sizeof(results));

    if (!g_npu_engine->infer(img, results)) {
        if (img.virt_addr) free(img.virt_addr);
        return -1;
    }

    char json_buf[8192];
    int written = snprintf(json_buf, sizeof(json_buf),
        "{\"frame_width\": %d, \"frame_height\": %d, \"detections\": [",
        img.width, img.height);

    for (int i = 0; i < results.count; i++) {
        int cls_id = results.results[i].cls_id;
        const char* label = g_npu_engine->get_label_name(cls_id);
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

        written += snprintf(json_buf + written, sizeof(json_buf) - written,
            "%s{\"class_id\": %d, \"label\": \"%s\", \"confidence\": %.2f, \"rel_box\": [%.4f, %.4f, %.4f, %.4f], \"box\": [%d, %d, %d, %d]}",
            (i > 0 ? ", " : ""),
            cls_id, label, conf, rx1, ry1, rx2, ry2, x1, y1, x2, y2
        );
        if (written >= (int)sizeof(json_buf) - 4) break;
    }
    written += snprintf(json_buf + written, sizeof(json_buf) - written, "]}");

    printf("[detect_file_for_cli] Targets: %d, JSON: %s\n", results.count, json_buf);

    if (out_json_path && out_json_path[0] != '\0') {
        FILE* fp = fopen(out_json_path, "w");
        if (fp) {
            fputs(json_buf, fp);
            fclose(fp);
            printf("[detect_file_for_cli] JSON results saved to: %s\n", out_json_path);
        }
    }

    if (out_image_path && out_image_path[0] != '\0') {
        g_gpu_renderer->draw_detections(img, results);
        write_image(out_image_path, &img);
        printf("[detect_file_for_cli] Annotated result image saved to: %s\n", out_image_path);
    }

    if (img.virt_addr) {
        free(img.virt_addr);
    }
    return results.count;
}
```

src/detect_cli.cpp

```c
#include "detect.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

void print_help(const char* prog) {
    printf("=========================================================================\n");
    printf("  YOLOv8 Hardware-Accelerated Detection CLI Utility\n");
    printf("=========================================================================\n");
    printf("Usage:\n");
    printf("  %s <input_image> [output_image] [output_json]\n\n", prog);
    printf("Arguments:\n");
    printf("  input_image   Path to input image (.jpg / .png / .data) [Required]\n");
    printf("  output_image  Path to save annotated box image (default: ./result.jpg)\n");
    printf("  output_json   Path to save detection JSON (default: ./result.json)\n\n");
    printf("Examples:\n");
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
        fprintf(stderr, "[ERROR] Cannot access input image: %s\n", image_path);
        return 1;
    }

    printf("=========================================================\n");
    printf("  YOLOv8 Hardware Detection Running...\n");
    printf("=========================================================\n");
    printf("  • Input Image   : %s\n", image_path);
    printf("  • Output Image  : %s\n", out_image);
    printf("  • Output JSON   : %s\n", out_json);
    printf("=========================================================\n\n");

    int ret = detect_file_for_cli(image_path, out_json, out_image);
    if (ret >= 0) {
        printf("\n>>> [SUCCESS] Detection completed. Result image and JSON generated.\n");
    } else {
        printf("\n>>> [FAILED] Detection failed (code: %d).\n", ret);
    }
    return (ret >= 0 ? 0 : 1);
}
```

build.sh

```sh
#!/bin/bash
set -e

# Base directories
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
WORKSPACE_DIR=$(cd "${SCRIPT_DIR}/.." && pwd)
TOOLCHAIN_DIR="${WORKSPACE_DIR}/toolchain"

# Configure Cross-Compiler Toolchain Environment
if [ -d "${TOOLCHAIN_DIR}/bin" ]; then
    export PATH="${TOOLCHAIN_DIR}/bin:${PATH}"
    export CC=aarch64-none-linux-gnu-gcc
    export CXX=aarch64-none-linux-gnu-g++
    export AR=aarch64-none-linux-gnu-ar
    export RANLIB=aarch64-none-linux-gnu-ranlib
    echo "[build.sh] Using cross-compiler toolchain: ${CC}"
else
    echo "[build.sh] Toolchain not found in ${TOOLCHAIN_DIR}, falling back to default compiler"
fi

BUILD_DIR="${SCRIPT_DIR}/build"
mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"

echo "[build.sh] Running CMake for modular aarch64 Linux library..."
cmake "${SCRIPT_DIR}" \
    -DCMAKE_SYSTEM_NAME=Linux \
    -DCMAKE_SYSTEM_PROCESSOR=aarch64 \
    -DCMAKE_C_COMPILER="${CC:-gcc}" \
    -DCMAKE_CXX_COMPILER="${CXX:-g++}" \
    -DCMAKE_BUILD_TYPE=Release

echo "[build.sh] Compiling libdetect.so & detect_cli..."
make -j$(nproc)

echo "[build.sh] Syncing runtime libraries..."
mkdir -p "${BUILD_DIR}/lib"
cp -f "${SCRIPT_DIR}/3rdparty/rknn_model_zoo/3rdparty/rknpu2/Linux/aarch64/librknnrt.so" "${BUILD_DIR}/" 2>/dev/null || true
cp -f "${SCRIPT_DIR}/3rdparty/rknn_model_zoo/3rdparty/librga/Linux/aarch64/librga.so" "${BUILD_DIR}/" 2>/dev/null || true
cp -f "${SCRIPT_DIR}/3rdparty/rknn_model_zoo/3rdparty/rknpu2/Linux/aarch64/librknnrt.so" "${BUILD_DIR}/lib/" 2>/dev/null || true
cp -f "${SCRIPT_DIR}/3rdparty/rknn_model_zoo/3rdparty/librga/Linux/aarch64/librga.so" "${BUILD_DIR}/lib/" 2>/dev/null || true

echo "========================================================="
echo "Build Successful!"
echo "  • Dynamic Library : ${BUILD_DIR}/libdetect.so"
echo "  • CLI Executable  : ${BUILD_DIR}/detect_cli"
ls -lh "${BUILD_DIR}/libdetect.so" "${BUILD_DIR}/detect_cli"
echo "========================================================="
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
    src/detect.cpp
    src/hardware/NpuInferenceEngine.cc
    src/hardware/RgaProcessor.cc
    src/hardware/VpuDecoder.cc
    src/hardware/GpuRenderer.cc
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

add_executable(detect_cli src/detect_cli.cpp)
target_link_libraries(detect_cli detect_shared pthread dl m)
set_target_properties(detect_cli PROPERTIES BUILD_WITH_INSTALL_RPATH TRUE)
set_target_properties(detect_cli PROPERTIES INSTALL_RPATH "$ORIGIN:$ORIGIN/../lib:/usr/local/lib:/usr/lib")
```
