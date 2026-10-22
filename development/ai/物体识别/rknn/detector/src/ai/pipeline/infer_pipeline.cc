#include "ai/pipeline/infer_pipeline.h"
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <algorithm>

#if !defined(DISABLE_RGA)
#include "im2d.h"
#include "rga.h"
#include "RgaApi.h"
#endif

static std::mutex s_pipeline_rga_mutex;

InferPipeline::InferPipeline(const std::string& name,
                             std::vector<std::shared_ptr<IModelInfer>> stages)
    : _name(name),
      _stages(std::move(stages)) {
}

InferPipeline::InferPipeline(const std::string& name,
                             std::initializer_list<std::shared_ptr<IModelInfer>> stages)
    : _name(name),
      _stages(stages) {
}

InferPipeline::InferPipeline(const std::string& name,
                             std::shared_ptr<IModelInfer> first_stage,
                             std::shared_ptr<IModelInfer> second_stage)
    : _name(name) {
    if (first_stage) _stages.push_back(first_stage);
    if (second_stage) _stages.push_back(second_stage);
}

InferPipeline::~InferPipeline() {
    release();
}

InferPipeline& InferPipeline::add_stage(std::shared_ptr<IModelInfer> stage) {
    std::lock_guard<std::recursive_mutex> lock(_mutex);
    if (stage) {
        _stages.push_back(stage);
    }
    return *this;
}

bool InferPipeline::init(const std::string& model_path, const std::string& label_path) {
    std::lock_guard<std::recursive_mutex> lock(_mutex);
    if (is_initialized()) {
        return true;
    }

    if (_stages.empty()) {
        fprintf(stderr, "[InferPipeline:%s] 初始化失败: 流水线未包含任何阶段模型\n", _name.c_str());
        return false;
    }

    for (size_t i = 0; i < _stages.size(); ++i) {
        auto& stage = _stages[i];
        if (!stage) {
            fprintf(stderr, "[InferPipeline:%s] 初始化失败: 第 %zu 阶段模型指针为空\n", _name.c_str(), i);
            release();
            return false;
        }

        if (!stage->is_initialized()) {
            bool ok = (i == 0) ? stage->init(model_path, label_path) : stage->init();
            if (!ok) {
                fprintf(stderr, "[InferPipeline:%s] 第 %zu 阶段模型 [%s] 初始化失败\n",
                        _name.c_str(), i, stage->name().c_str());
                release();
                return false;
            }
        }
    }

    std::string stages_info;
    for (size_t i = 0; i < _stages.size(); ++i) {
        if (i > 0) stages_info += " ➔ ";
        stages_info += _stages[i]->name();
    }
    printf("[InferPipeline:%s] 流水线就绪: 共 %zu 阶段 (%s)\n",
           _name.c_str(), _stages.size(), stages_info.c_str());
    fflush(stdout);
    return true;
}

void InferPipeline::release() {
    std::lock_guard<std::recursive_mutex> lock(_mutex);
    for (auto& stage : _stages) {
        if (stage) {
            stage->release();
        }
    }
    _stages.clear();
}

bool InferPipeline::is_initialized() const {
    if (_stages.empty()) {
        return false;
    }
    for (const auto& stage : _stages) {
        if (!stage || !stage->is_initialized()) {
            return false;
        }
    }
    return true;
}

int InferPipeline::model_width() const {
    return (!_stages.empty() && _stages[0]) ? _stages[0]->model_width() : 640;
}

int InferPipeline::model_height() const {
    return (!_stages.empty() && _stages[0]) ? _stages[0]->model_height() : 640;
}

int InferPipeline::model_channel() const {
    return (!_stages.empty() && _stages[0]) ? _stages[0]->model_channel() : 3;
}

const char* InferPipeline::get_label_name(int cls_id) {
    return (!_stages.empty() && _stages[0]) ? _stages[0]->get_label_name(cls_id) : "unknown";
}

const std::vector<std::string>& InferPipeline::get_labels() const {
    static const std::vector<std::string> empty_vec;
    return (!_stages.empty() && _stages[0]) ? _stages[0]->get_labels() : empty_vec;
}

void* InferPipeline::input_buf() {
    return (!_stages.empty() && _stages[0]) ? _stages[0]->input_buf() : nullptr;
}

bool InferPipeline::process_stage_from_frame(size_t stage_idx,
                                             const std::shared_ptr<VpuDecoder::FrameBuffer>& frame,
                                             YoloDetectObject& obj) {
    if (stage_idx >= _stages.size()) return false;
    auto& curr_stage = _stages[stage_idx];
    if (!frame || !curr_stage || !curr_stage->is_initialized() || !curr_stage->input_buf()) {
        return false;
    }

    int orig_w = frame->width;
    int orig_h = frame->height;
    if (orig_w <= 0 || orig_h <= 0) {
        return false;
    }

    int x1 = std::max(0, obj.box[0]);
    int y1 = std::max(0, obj.box[1]);
    int x2 = std::min(orig_w, obj.box[2]);
    int y2 = std::min(orig_h, obj.box[3]);
    int cw = x2 - x1;
    int ch = y2 - y1;
    if (cw <= 4 || ch <= 4) {
        return false;
    }

    int target_w = curr_stage->model_width();
    int target_h = curr_stage->model_height();
    unsigned char* dst_rgb = static_cast<unsigned char*>(curr_stage->input_buf());

    int src_hor_stride = std::max(frame->hor_stride, orig_w);
    int src_ver_stride = std::max(frame->ver_stride, orig_h);

    bool rga_ok = false;
#if !defined(DISABLE_RGA)
    if (frame->dma_fd >= 0) {
        rga_buffer_t rga_src = wrapbuffer_fd(frame->dma_fd, orig_w, orig_h, RK_FORMAT_YCbCr_420_SP, src_hor_stride, src_ver_stride);
        rga_buffer_t rga_dst = wrapbuffer_virtualaddr(dst_rgb, target_w, target_h, RK_FORMAT_RGB_888, target_w, target_h);
        im_rect srect = {x1, y1, cw, ch};
        im_rect drect = {0, 0, target_w, target_h};
        rga_buffer_t pat;
        memset(&pat, 0, sizeof(rga_buffer_t));
        im_rect prect = {0, 0, 0, 0};
        if (imcheck(rga_src, rga_dst, srect, drect) == IM_STATUS_NOERROR) {
            std::lock_guard<std::mutex> rga_lock(s_pipeline_rga_mutex);
            int ret_rga = improcess(rga_src, rga_dst, pat, srect, drect, prect, 0);
            if (ret_rga == IM_STATUS_SUCCESS || ret_rga > 0) {
                rga_ok = true;
            }
        }
    }
#endif

    if (!rga_ok) {
        const unsigned char* y_plane = nullptr;
        if (!frame->data.empty()) {
            y_plane = frame->data.data();
        } else if (frame->mpp_buf) {
            y_plane = static_cast<const unsigned char*>(VpuDecoder::mpp_buf_get_ptr(frame->mpp_buf));
        }
        if (!y_plane) {
            return false;
        }

        const unsigned char* uv_plane = y_plane + (size_t)src_hor_stride * src_ver_stride;
        float scale_x = (float)cw / (float)target_w;
        float scale_y = (float)ch / (float)target_h;

        for (int dy = 0; dy < target_h; ++dy) {
            int sy = y1 + (int)(dy * scale_y);
            if (sy >= orig_h) sy = orig_h - 1;
            const unsigned char* py = y_plane + sy * src_hor_stride;
            const unsigned char* puv = uv_plane + (sy / 2) * src_hor_stride;
            unsigned char* pdst = dst_rgb + dy * target_w * 3;

            for (int dx = 0; dx < target_w; ++dx) {
                int sx = x1 + (int)(dx * scale_x);
                if (sx >= orig_w) sx = orig_w - 1;

                int y_val = py[sx];
                int uv_idx = (sx / 2) * 2;
                if (uv_idx + 1 >= src_hor_stride) {
                    uv_idx = (src_hor_stride >= 2) ? src_hor_stride - 2 : 0;
                }
                int u_val = puv[uv_idx];
                int v_val = puv[uv_idx + 1];

                int c = y_val - 16;
                int d = u_val - 128;
                int e = v_val - 128;

                int r = (298 * c + 409 * e + 128) >> 8;
                int g = (298 * c - 100 * d - 208 * e + 128) >> 8;
                int b = (298 * c + 516 * d + 128) >> 8;

                pdst[dx * 3 + 0] = (unsigned char)(r < 0 ? 0 : (r > 255 ? 255 : r));
                pdst[dx * 3 + 1] = (unsigned char)(g < 0 ? 0 : (g > 255 ? 255 : g));
                pdst[dx * 3 + 2] = (unsigned char)(b < 0 ? 0 : (b > 255 ? 255 : b));
            }
        }
    }

    image_buffer_t crop_buf;
    memset(&crop_buf, 0, sizeof(crop_buf));
    crop_buf.width = target_w;
    crop_buf.height = target_h;
    crop_buf.width_stride = target_w;
    crop_buf.height_stride = target_h;
    crop_buf.format = IMAGE_FORMAT_RGB888;
    crop_buf.virt_addr = dst_rgb;
    crop_buf.size = target_w * target_h * 3;
    crop_buf.fd = -1;

    DetectResult sub_res;
    if (curr_stage->infer(crop_buf, sub_res) && !sub_res.objects.empty()) {
        const auto& sub_obj = sub_res.objects[0];
        // 1. 如果该阶段识别出了文字属性 (如 OCR/车牌/条码等)
        if (!sub_obj.text.empty()) {
            obj.text = sub_obj.text;
        }
        // 2. 如果该阶段是一个子目标定位模型 (如车辆 -> 车牌)，精细化边界框
        if (sub_obj.box[2] > sub_obj.box[0] && sub_obj.box[3] > sub_obj.box[1]) {
            int new_x1 = x1 + (sub_obj.box[0] * cw) / target_w;
            int new_y1 = y1 + (sub_obj.box[1] * ch) / target_h;
            int new_x2 = x1 + (sub_obj.box[2] * cw) / target_w;
            int new_y2 = y1 + (sub_obj.box[3] * ch) / target_h;
            obj.box[0] = std::max(0, std::min(orig_w, new_x1));
            obj.box[1] = std::max(0, std::min(orig_h, new_y1));
            obj.box[2] = std::max(0, std::min(orig_w, new_x2));
            obj.box[3] = std::max(0, std::min(orig_h, new_y2));
            if (orig_w > 0 && orig_h > 0) {
                obj.rel_box[0] = (float)obj.box[0] / (float)orig_w;
                obj.rel_box[1] = (float)obj.box[1] / (float)orig_h;
                obj.rel_box[2] = (float)obj.box[2] / (float)orig_w;
                obj.rel_box[3] = (float)obj.box[3] / (float)orig_h;
            }
            if (!sub_obj.label.empty()) {
                obj.label = sub_obj.label;
                obj.class_id = sub_obj.class_id;
            }
        }
    }
    return true;
}

bool InferPipeline::process_stage_from_img(size_t stage_idx,
                                           image_buffer_t& img,
                                           YoloDetectObject& obj) {
    if (stage_idx >= _stages.size()) return false;
    auto& curr_stage = _stages[stage_idx];
    if (!img.virt_addr || !curr_stage || !curr_stage->is_initialized() || !curr_stage->input_buf()) {
        return false;
    }

    int x1 = std::max(0, obj.box[0]);
    int y1 = std::max(0, obj.box[1]);
    int x2 = std::min(img.width, obj.box[2]);
    int y2 = std::min(img.height, obj.box[3]);
    int cw = x2 - x1;
    int ch = y2 - y1;
    if (cw <= 4 || ch <= 4) {
        return false;
    }

    int target_w = curr_stage->model_width();
    int target_h = curr_stage->model_height();
    unsigned char* dst_rgb = static_cast<unsigned char*>(curr_stage->input_buf());

    if (img.format == IMAGE_FORMAT_RGB888) {
        float scale_x = (float)cw / (float)target_w;
        float scale_y = (float)ch / (float)target_h;

        for (int dy = 0; dy < target_h; ++dy) {
            int sy = y1 + (int)(dy * scale_y);
            if (sy >= img.height) sy = img.height - 1;
            const unsigned char* psrc = img.virt_addr + sy * img.width_stride * 3;
            unsigned char* pdst = dst_rgb + dy * target_w * 3;

            for (int dx = 0; dx < target_w; ++dx) {
                int sx = x1 + (int)(dx * scale_x);
                if (sx >= img.width) sx = img.width - 1;
                pdst[dx * 3 + 0] = psrc[sx * 3 + 0];
                pdst[dx * 3 + 1] = psrc[sx * 3 + 1];
                pdst[dx * 3 + 2] = psrc[sx * 3 + 2];
            }
        }
    } else {
        image_buffer_t dst_img;
        memset(&dst_img, 0, sizeof(image_buffer_t));
        dst_img.width = target_w;
        dst_img.height = target_h;
        dst_img.width_stride = target_w;
        dst_img.height_stride = target_h;
        dst_img.format = IMAGE_FORMAT_RGB888;
        dst_img.virt_addr = dst_rgb;
        dst_img.size = target_w * target_h * 3;
        dst_img.fd = -1;

        image_rect_t src_box = {x1, y1, x2, y2};
        image_rect_t dst_box = {0, 0, target_w, target_h};
        if (convert_image(&img, &dst_img, &src_box, &dst_box, 0) < 0) {
            return false;
        }
    }

    image_buffer_t crop_buf;
    memset(&crop_buf, 0, sizeof(crop_buf));
    crop_buf.width = target_w;
    crop_buf.height = target_h;
    crop_buf.width_stride = target_w;
    crop_buf.height_stride = target_h;
    crop_buf.format = IMAGE_FORMAT_RGB888;
    crop_buf.virt_addr = dst_rgb;
    crop_buf.size = target_w * target_h * 3;
    crop_buf.fd = -1;

    DetectResult sub_res;
    if (curr_stage->infer(crop_buf, sub_res) && !sub_res.objects.empty()) {
        const auto& sub_obj = sub_res.objects[0];
        if (!sub_obj.text.empty()) {
            obj.text = sub_obj.text;
        }
        if (sub_obj.box[2] > sub_obj.box[0] && sub_obj.box[3] > sub_obj.box[1]) {
            int new_x1 = x1 + (sub_obj.box[0] * cw) / target_w;
            int new_y1 = y1 + (sub_obj.box[1] * ch) / target_h;
            int new_x2 = x1 + (sub_obj.box[2] * cw) / target_w;
            int new_y2 = y1 + (sub_obj.box[3] * ch) / target_h;
            obj.box[0] = std::max(0, std::min(img.width, new_x1));
            obj.box[1] = std::max(0, std::min(img.height, new_y1));
            obj.box[2] = std::max(0, std::min(img.width, new_x2));
            obj.box[3] = std::max(0, std::min(img.height, new_y2));
            if (img.width > 0 && img.height > 0) {
                obj.rel_box[0] = (float)obj.box[0] / (float)img.width;
                obj.rel_box[1] = (float)obj.box[1] / (float)img.height;
                obj.rel_box[2] = (float)obj.box[2] / (float)img.width;
                obj.rel_box[3] = (float)obj.box[3] / (float)img.height;
            }
            if (!sub_obj.label.empty()) {
                obj.label = sub_obj.label;
                obj.class_id = sub_obj.class_id;
            }
        }
    }
    return true;
}

bool InferPipeline::infer(image_buffer_t& img, DetectResult& result) {
    std::lock_guard<std::recursive_mutex> lock(_mutex);
    if (!is_initialized() || _stages.empty()) {
        return false;
    }

    // 第一阶段：初始全图检测/定位
    bool ok = _stages[0]->infer(img, result);
    if (!ok || result.objects.empty()) {
        return ok;
    }

    // 后续各阶段：依次对前续阶段产出的目标进行 ROI 裁剪与级联推理
    for (size_t s = 1; s < _stages.size(); ++s) {
        for (auto& obj : result.objects) {
            process_stage_from_img(s, img, obj);
        }
    }
    return true;
}

bool InferPipeline::infer_frame(const std::shared_ptr<VpuDecoder::FrameBuffer>& frame, DetectResult& result) {
    std::lock_guard<std::recursive_mutex> lock(_mutex);
    if (!is_initialized() || _stages.empty()) {
        return false;
    }

    // 第一阶段：初始视频帧检测/定位
    bool ok = _stages[0]->infer_frame(frame, result);
    if (!ok || result.objects.empty()) {
        return ok;
    }

    // 后续各阶段：依次对前续阶段产出的目标进行 ROI 裁剪与级联推理
    for (size_t s = 1; s < _stages.size(); ++s) {
        for (auto& obj : result.objects) {
            process_stage_from_frame(s, frame, obj);
        }
    }
    return true;
}

std::shared_ptr<IModelInfer> InferPipeline::clone(uint32_t core_mask) {
    std::lock_guard<std::recursive_mutex> lock(_mutex);
    if (!is_initialized()) {
        return nullptr;
    }

    std::vector<std::shared_ptr<IModelInfer>> cloned_stages;
    cloned_stages.reserve(_stages.size());
    for (const auto& stage : _stages) {
        auto cloned = stage->clone(core_mask);
        if (!cloned) {
            return nullptr;
        }
        cloned_stages.push_back(cloned);
    }

    return std::make_shared<InferPipeline>(_name, std::move(cloned_stages));
}
