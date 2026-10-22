#include "ai/infer_manager/infer_manager.h"
#include "ai/register/register.h"
#include "ai/pipeline/infer_pipeline.h"
#include <cstdio>

InferManager::InferManager(bool auto_register) {
    if (auto_register) {
        register_models(*this);
    }
}

InferManager::~InferManager() {
    release();
}

bool InferManager::register_infer(std::shared_ptr<IModelInfer> infer) {
    if (!infer) {
        return false;
    }
    std::lock_guard<std::recursive_mutex> lock(_mutex);
    for (const auto& m : _models) {
        if (m && m->name() == infer->name()) {
            return false; // 已存在同名模型
        }
    }
    _models.push_back(infer);
    return true;
}

bool InferManager::register_pipeline(const std::string& name,
                                     const std::vector<std::shared_ptr<IModelInfer>>& stages) {
    if (stages.empty()) {
        fprintf(stderr, "[InferManager] register_pipeline 失败: 流水线 [%s] 阶段列表为空\n",
                name.c_str());
        return false;
    }
    for (size_t i = 0; i < stages.size(); ++i) {
        if (!stages[i]) {
            fprintf(stderr, "[InferManager] register_pipeline 失败: 流水线 [%s] 第 %zu 阶段推理器为空\n",
                    name.c_str(), i);
            return false;
        }
    }
    auto pipeline = std::make_shared<InferPipeline>(name, stages);
    return register_infer(pipeline);
}

bool InferManager::init(const std::string& model_path, const std::string& label_path) {
    std::lock_guard<std::recursive_mutex> lock(_mutex);
    if (_models.empty()) {
        register_models(*this);
    }

    int success_count = 0;
    for (auto& model : _models) {
        if (!model) continue;
        if (model->is_initialized()) {
            success_count++;
            continue;
        }

        if (!model->init(model_path, label_path)) {
            fprintf(stderr, "[InferManager] 提示: 模型 [%s] 加载跳过或文件未就绪\n", model->name().c_str());
            continue;
        }

        printf("[InferManager] 模型 [%s] 成功加载并就绪\n", model->name().c_str());
        fflush(stdout);
        success_count++;
    }

    return success_count > 0;
}

void InferManager::release() {
    std::lock_guard<std::recursive_mutex> lock(_mutex);
    for (auto& model : _models) {
        if (model) {
            model->release();
        }
    }
    _models.clear();
}

bool InferManager::is_initialized() const {
    std::lock_guard<std::recursive_mutex> lock(_mutex);
    for (const auto& model : _models) {
        if (model && model->is_initialized()) {
            return true;
        }
    }
    return false;
}

std::shared_ptr<IModelInfer> InferManager::model(size_t index) const {
    std::lock_guard<std::recursive_mutex> lock(_mutex);
    return (index < _models.size()) ? _models[index] : nullptr;
}

size_t InferManager::model_count() const {
    std::lock_guard<std::recursive_mutex> lock(_mutex);
    return _models.size();
}

std::shared_ptr<IModelInfer> InferManager::get_model(const std::string& name) const {
    std::lock_guard<std::recursive_mutex> lock(_mutex);

    const std::string& target = (name.empty() || name == "default") ? "industry" : name;

    for (const auto& m : _models) {
        if (m && m->name() == target) {
            return m;
        }
    }

    fprintf(stderr, "[InferManager] 错误: 未找到与 [%s] 匹配的有效模型实例 (严禁隐式回退)\n", target.c_str());
    return nullptr;
}

std::vector<std::string> InferManager::get_loaded_models() const {
    std::lock_guard<std::recursive_mutex> lock(_mutex);
    std::vector<std::string> names;
    for (const auto& m : _models) {
        if (m && m->is_initialized()) {
            names.push_back(m->name());
        }
    }
    return names;
}

std::shared_ptr<InferManager> InferManager::clone(uint32_t core_mask) {
    std::lock_guard<std::recursive_mutex> lock(_mutex);
    auto cloned = std::make_shared<InferManager>(false);
    for (const auto& model : _models) {
        if (!model || !model->is_initialized()) continue;
        auto ch_model = model->clone(core_mask);
        if (ch_model) {
            cloned->register_infer(ch_model);
        }
    }
    return cloned;
}

void* InferManager::input_buf(const std::string& model_name) const {
    auto m = get_model(model_name);
    return m ? m->input_buf() : nullptr;
}

int InferManager::input_width(const std::string& model_name) const {
    auto m = get_model(model_name);
    return m ? m->model_width() : 0;
}

int InferManager::input_height(const std::string& model_name) const {
    auto m = get_model(model_name);
    return m ? m->model_height() : 0;
}

int InferManager::input_channel(const std::string& model_name) const {
    auto m = get_model(model_name);
    return m ? m->model_channel() : 3;
}

const char* InferManager::get_label_name(int cls_id) const {
    return get_label_name("", cls_id);
}

const char* InferManager::get_label_name(const std::string& model_name, int cls_id) const {
    auto m = get_model(model_name);
    if (m) {
        return m->get_label_name(cls_id);
    }
    return "object";
}
