#include "ai/pipeline/infer_pipeline.h"
#include "ai/register/register.h"

InferPipeline::InferPipeline(bool auto_register) {
    if (auto_register) {
        register_models(*this);
    }
}

InferPipeline::InferPipeline(std::shared_ptr<IModelInfer> model) {
    if (model) {
        _models.push_back(model);
    }
}

InferPipeline::~InferPipeline() {
    release();
}

bool InferPipeline::init(const std::string& model_path, const std::string& label_path) {
    if (_models.empty()) {
        register_models(*this);
    }
    for (auto& model : _models) {
        if (!model) continue;
        if (model->is_initialized()) continue;
        if (!model->init(model_path, label_path)) {
            fprintf(stderr, "[engine] 模型 %s 加载失败\n", model->name().c_str());
            return false;
        }
        printf("[engine] 模型 %s 加载成功\n", model->name().c_str());
        fflush(stdout);
    }
    return true;
}

void InferPipeline::release() {
    for (auto& model : _models) {
        if (model) {
            model->release();
        }
    }
    _models.clear();
}

bool InferPipeline::is_initialized() const {
    if (_models.empty()) {
        return false;
    }
    for (const auto& model : _models) {
        if (!model || !model->is_initialized()) {
            return false;
        }
    }
    return true;
}

InferPipeline& InferPipeline::add(std::shared_ptr<IModelInfer> model) {
    if (model) {
        _models.push_back(model);
    }
    return *this;
}

void InferPipeline::clear() {
    release();
}

std::shared_ptr<InferPipeline> InferPipeline::clone(uint32_t core_mask) {
    auto cloned = std::make_shared<InferPipeline>(false);
    for (const auto& model : _models) {
        if (!model) continue;
        auto ch_model = model->clone(core_mask);
        if (!ch_model) {
            return nullptr;
        }
        cloned->add(ch_model);
    }
    return cloned;
}

void* InferPipeline::input_buf() const {
    return (!_models.empty() && _models[0]) ? _models[0]->input_buf() : nullptr;
}

int InferPipeline::input_width() const {
    return (!_models.empty() && _models[0]) ? _models[0]->model_width() : 0;
}

int InferPipeline::input_height() const {
    return (!_models.empty() && _models[0]) ? _models[0]->model_height() : 0;
}

int InferPipeline::input_channel() const {
    return (!_models.empty() && _models[0]) ? _models[0]->model_channel() : 3;
}

const char* InferPipeline::get_label_name(int cls_id) const {
    return (!_models.empty() && _models[0]) ? _models[0]->get_label_name(cls_id) : "object";
}

const char* InferPipeline::get_label_name(const std::string& model_name, int cls_id) const {
    auto m = find_model(model_name);
    if (m) {
        return m->get_label_name(cls_id);
    }
    return get_label_name(cls_id);
}

bool InferPipeline::process(const std::shared_ptr<VpuDecoder::FrameBuffer>& frame, DetectResult& result) {
    if (!frame || frame->data.empty() || _models.empty()) {
        return false;
    }

    result.objects.clear();
    result.orig_width = frame->width;
    result.orig_height = frame->height;
    result.frame_idx = frame->frame_idx;
    result.pts_ms = frame->pts_ms;

    for (auto& model : _models) {
        if (!model || !model->is_initialized()) {
            return false;
        }
        if (!model->infer_frame(frame, result)) {
            return false;
        }
    }
    return true;
}

bool InferPipeline::process(image_buffer_t& img, DetectResult& result) {
    if (_models.empty()) {
        return false;
    }

    result.objects.clear();
    if (result.orig_width <= 0) result.orig_width = img.width;
    if (result.orig_height <= 0) result.orig_height = img.height;

    for (auto& model : _models) {
        if (!model || !model->is_initialized()) {
            return false;
        }
        if (!model->infer(img, result)) {
            return false;
        }
    }
    return true;
}
