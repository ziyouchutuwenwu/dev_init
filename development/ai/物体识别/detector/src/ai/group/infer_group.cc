#include "ai/group/infer_group.h"
#include "hardware/rknn_model_loader.h"
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <algorithm>

#if !defined(DISABLE_RGA)
#include "im2d.h"
#include "rga.h"
#include "RgaApi.h"
#include "hardware/vpu_decoder.h"
#endif

InferGroup::InferGroup(const std::string& group_id, const std::string& desc)
    : _group_id(group_id),
      _desc(desc) {
}

InferGroup::InferGroup(const std::string& group_id,
                       std::vector<std::shared_ptr<IModelInfer>> steps)
    : _group_id(group_id),
      _steps(std::move(steps)) {
}

InferGroup::InferGroup(const std::string& group_id,
                       std::initializer_list<std::shared_ptr<IModelInfer>> steps)
    : _group_id(group_id),
      _steps(steps) {
}

InferGroup::InferGroup(const std::string& group_id,
                       std::shared_ptr<IModelInfer> single_step)
    : _group_id(group_id) {
    if (single_step) {
        _steps.push_back(single_step);
    }
}

InferGroup::~InferGroup() {
    release();
}

InferGroup& InferGroup::step(std::shared_ptr<IModelInfer> step_model) {
    std::lock_guard<std::recursive_mutex> lock(_mutex);
    if (step_model) {
        _steps.push_back(step_model);
    }
    return *this;
}

bool InferGroup::init(const std::string& model_path, const std::string& label_path) {
    std::lock_guard<std::recursive_mutex> lock(_mutex);
    if (is_initialized()) {
        return true;
    }

    if (_steps.empty()) {
        fprintf(stderr, "[InferGroup:%s] 初始化失败: 推理组未包含任何阶段模型\n", _group_id.c_str());
        return false;
    }

    for (size_t i = 0; i < _steps.size(); ++i) {
        auto& stage = _steps[i];
        if (!stage) {
            fprintf(stderr, "[InferGroup:%s] 初始化失败: 第 %zu 阶段模型指针为空\n", _group_id.c_str(), i);
            release();
            return false;
        }

        if (!stage->is_initialized()) {
            bool ok = (i == 0) ? stage->init(model_path, label_path) : stage->init();
            if (!ok) {
                fprintf(stderr, "[InferGroup:%s] 第 %zu 阶段模型 [%s] 初始化失败\n",
                        _group_id.c_str(), i, stage->model_id().c_str());
                release();
                return false;
            }
        }
    }

    std::string steps_info;
    for (size_t i = 0; i < _steps.size(); ++i) {
        if (i > 0) steps_info += " ➔ ";
        steps_info += _steps[i]->model_id();
    }
    printf("[InferGroup:%s] 推理组就绪: 共 %zu 阶段 (%s)\n",
           _group_id.c_str(), _steps.size(), steps_info.c_str());
    fflush(stdout);
    return true;
}

void InferGroup::release() {
    std::lock_guard<std::recursive_mutex> lock(_mutex);
    for (auto& stage : _steps) {
        if (stage) {
            stage->release();
        }
    }
    _steps.clear();
}

bool InferGroup::is_initialized() const {
    if (_steps.empty()) {
        return false;
    }
    for (const auto& stage : _steps) {
        if (!stage || !stage->is_initialized()) {
            return false;
        }
    }
    return true;
}

int InferGroup::model_width() const {
    return (!_steps.empty() && _steps[0]) ? _steps[0]->model_width() : 0;
}

int InferGroup::model_height() const {
    return (!_steps.empty() && _steps[0]) ? _steps[0]->model_height() : 0;
}

int InferGroup::model_channel() const {
    return (!_steps.empty() && _steps[0]) ? _steps[0]->model_channel() : 0;
}

const char* InferGroup::get_label_name(int cls_id) {
    return (!_steps.empty() && _steps[0]) ? _steps[0]->get_label_name(cls_id) : nullptr;
}

const std::vector<std::string>& InferGroup::get_labels() const {
    static const std::vector<std::string> empty_vec;
    if (!_steps.empty() && _steps[0]) {
        const auto& labels = _steps[0]->get_labels();
        if (!labels.empty()) {
            return labels;
        }
    }
    if (_cached_labels && !_cached_labels->empty()) {
        return *_cached_labels;
    }
    const char* const* list = RknnModelLoader::instance().get_labels_list(_group_id);
    if (list) {
        auto vec = std::make_shared<std::vector<std::string>>();
        for (int i = 0; list[i] != nullptr; ++i) {
            vec->emplace_back(list[i]);
        }
        if (!vec->empty()) {
            _cached_labels = vec;
            return *_cached_labels;
        }
    }
    return empty_vec;
}

void* InferGroup::input_buf() {
    return (!_steps.empty() && _steps[0]) ? _steps[0]->input_buf() : nullptr;
}

bool InferGroup::process_stage_from_frame(size_t stage_idx,
                                         const std::shared_ptr<VpuDecoder::FrameBuffer>& frame,
                                         YoloDetectObject& obj) {
    if (stage_idx >= _steps.size()) return false;
    auto& curr_stage = _steps[stage_idx];
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

    x1 = (x1 / 2) * 2;
    y1 = (y1 / 2) * 2;
    x2 = ((x2 + 1) / 2) * 2;
    if (x2 > orig_w) x2 = (orig_w / 2) * 2;
    y2 = ((y2 + 1) / 2) * 2;
    if (y2 > orig_h) y2 = (orig_h / 2) * 2;

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
        bool is_sub_bbox = (sub_obj.box[0] > 0 || sub_obj.box[1] > 0 ||
                            sub_obj.box[2] < target_w || sub_obj.box[3] < target_h);
        if (is_sub_bbox && sub_obj.box[2] > sub_obj.box[0] && sub_obj.box[3] > sub_obj.box[1]) {
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

bool InferGroup::process_stage_from_img(size_t stage_idx,
                                       image_buffer_t& img,
                                       YoloDetectObject& obj) {
    if (stage_idx >= _steps.size()) return false;
    auto& curr_stage = _steps[stage_idx];
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
        bool is_sub_bbox = (sub_obj.box[0] > 0 || sub_obj.box[1] > 0 ||
                            sub_obj.box[2] < target_w || sub_obj.box[3] < target_h);
        if (is_sub_bbox && sub_obj.box[2] > sub_obj.box[0] && sub_obj.box[3] > sub_obj.box[1]) {
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

bool InferGroup::infer(image_buffer_t& img, DetectResult& result) {
    std::lock_guard<std::recursive_mutex> lock(_mutex);
    if (!is_initialized() || _steps.empty()) {
        return false;
    }

    bool ok = _steps[0]->infer(img, result);
    if (!ok || result.objects.empty()) {
        return ok;
    }

    for (size_t s = 1; s < _steps.size(); ++s) {
        for (auto& obj : result.objects) {
            process_stage_from_img(s, img, obj);
        }
    }
    for (auto& obj : result.objects) {
        obj.model_id = _group_id;
    }
    return true;
}

bool InferGroup::infer_frame(const std::shared_ptr<VpuDecoder::FrameBuffer>& frame, DetectResult& result) {
    std::lock_guard<std::recursive_mutex> lock(_mutex);
    if (!is_initialized() || _steps.empty()) {
        return false;
    }

    bool ok = _steps[0]->infer_frame(frame, result);
    if (!ok || result.objects.empty()) {
        return ok;
    }

    for (size_t s = 1; s < _steps.size(); ++s) {
        for (auto& obj : result.objects) {
            process_stage_from_frame(s, frame, obj);
        }
    }
    for (auto& obj : result.objects) {
        obj.model_id = _group_id;
    }
    return true;
}

std::shared_ptr<IModelInfer> InferGroup::clone(uint32_t core_mask) {
    std::lock_guard<std::recursive_mutex> lock(_mutex);
    if (!is_initialized()) {
        return nullptr;
    }

    std::vector<std::shared_ptr<IModelInfer>> cloned_steps;
    cloned_steps.reserve(_steps.size());
    for (const auto& stage : _steps) {
        auto cloned = stage->clone(core_mask);
        if (!cloned) {
            return nullptr;
        }
        cloned_steps.push_back(cloned);
    }

    auto g = std::make_shared<InferGroup>(_group_id, std::move(cloned_steps));
    g->set_desc(_desc);
    return g;
}
