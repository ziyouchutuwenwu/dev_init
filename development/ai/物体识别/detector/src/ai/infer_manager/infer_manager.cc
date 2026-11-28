#include "ai/infer_manager/infer_manager.h"
#include "ai/register/register.h"
#include "hardware/rknn_model_loader.h"
#include <cstdio>

InferManager::InferManager(bool auto_register) {
    if (auto_register) {
        register_models(*this);
    }
}

InferManager::~InferManager() {
    release();
}

InferGroup& InferManager::register_group(const std::string& group_id, const std::string& desc) {
    std::lock_guard<std::recursive_mutex> lock(_mutex);
    for (auto& g : _groups) {
        if (g && g->group_id() == group_id) {
            if (!desc.empty()) g->set_desc(desc);
            return *g;
        }
    }
    auto new_group = std::make_shared<InferGroup>(group_id, desc);
    _groups.push_back(new_group);
    return *new_group;
}

bool InferManager::register_group(std::shared_ptr<InferGroup> group) {
    if (!group || group->group_id().empty()) {
        return false;
    }
    std::lock_guard<std::recursive_mutex> lock(_mutex);
    for (size_t i = 0; i < _groups.size(); ++i) {
        if (_groups[i] && _groups[i]->group_id() == group->group_id()) {
            _groups[i] = group;
            return true;
        }
    }
    _groups.push_back(group);
    return true;
}

bool InferManager::register_group(const std::string& group_id, std::shared_ptr<IModelInfer> single_infer) {
    if (group_id.empty() || !single_infer) {
        return false;
    }
    auto g = std::make_shared<InferGroup>(group_id, single_infer);
    return register_group(g);
}

bool InferManager::register_group(const std::string& group_id,
                                  const std::vector<std::shared_ptr<IModelInfer>>& steps) {
    if (group_id.empty() || steps.empty()) {
        return false;
    }
    auto g = std::make_shared<InferGroup>(group_id, steps);
    return register_group(g);
}

bool InferManager::register_group(const std::string& group_id,
                                  std::initializer_list<std::shared_ptr<IModelInfer>> steps) {
    if (group_id.empty() || steps.size() == 0) {
        return false;
    }
    auto g = std::make_shared<InferGroup>(group_id, steps);
    return register_group(g);
}

bool InferManager::bind_channel(int channel_id, const std::string& group_id) {
    if (channel_id < 0) {
        return false;
    }
    if (group_id.empty()) {
        return unbind_channel(channel_id);
    }
    std::lock_guard<std::mutex> lock(_channel_mutex);
    _channel_groups[channel_id] = group_id;
    return true;
}

bool InferManager::unbind_channel(int channel_id) {
    if (channel_id < 0) {
        return false;
    }
    std::lock_guard<std::mutex> lock(_channel_mutex);
    return _channel_groups.erase(channel_id) > 0;
}

bool InferManager::is_channel_bound(int channel_id) const {
    if (channel_id < 0) return false;
    std::lock_guard<std::mutex> lock(_channel_mutex);
    auto it = _channel_groups.find(channel_id);
    return (it != _channel_groups.end() && !it->second.empty());
}

std::string InferManager::get_channel_group(int channel_id) const {
    std::lock_guard<std::mutex> lock(_channel_mutex);
    auto it = _channel_groups.find(channel_id);
    if (it != _channel_groups.end()) {
        return it->second;
    }
    return "";
}

bool InferManager::bind_model_file(const std::string& model_id, const std::string& file_path) {
    if (model_id.empty() || file_path.empty()) {
        return false;
    }
    std::lock_guard<std::mutex> lock(_channel_mutex);
    _model_files[model_id] = file_path;
    RknnModelLoader::instance().bind_model_file(model_id, file_path);
    return true;
}

std::string InferManager::get_model_file(const std::string& model_id) const {
    std::lock_guard<std::mutex> lock(_channel_mutex);
    auto it = _model_files.find(model_id);
    if (it != _model_files.end()) {
        return it->second;
    }
    return RknnModelLoader::instance().get_bound_model_file(model_id);
}

std::shared_ptr<InferGroup> InferManager::get_group(const std::string& group_id) const {
    std::lock_guard<std::recursive_mutex> lock(_mutex);
    if (group_id.empty()) {
        return _groups.empty() ? nullptr : _groups[0];
    }
    for (const auto& g : _groups) {
        if (g && g->group_id() == group_id) {
            return g;
        }
    }
    return nullptr;
}

std::shared_ptr<InferGroup> InferManager::get_group_for_channel(int channel_id) {
    std::lock_guard<std::recursive_mutex> lock(_mutex);
    // 1. 如果该通道明确绑定了 group，则 channel 只用绑定的模型推理：
    {
        std::lock_guard<std::mutex> ch_lock(_channel_mutex);
        auto it = _channel_groups.find(channel_id);
        if (it != _channel_groups.end() && !it->second.empty()) {
            for (const auto& g : _groups) {
                if (g && g->group_id() == it->second) {
                    return g;
                }
            }
            return nullptr;
        }
    }

    // 2. 如果不绑定 channel，就是协程自动切换（轮转切换所有就绪的组）：
    std::vector<std::shared_ptr<InferGroup>> active_groups;
    for (const auto& g : _groups) {
        if (g && g->is_initialized()) {
            active_groups.push_back(g);
        }
    }
    if (active_groups.empty()) {
        return _groups.empty() ? nullptr : _groups[0];
    }

    uint32_t idx = _auto_switch_counter.fetch_add(1);
    return active_groups[idx % active_groups.size()];
}

std::vector<std::string> InferManager::get_registered_groups() const {
    std::lock_guard<std::recursive_mutex> lock(_mutex);
    std::vector<std::string> ids;
    for (const auto& g : _groups) {
        if (g && g->is_initialized()) {
            ids.push_back(g->group_id());
        }
    }
    return ids;
}

std::vector<InferManager::GroupInfo> InferManager::get_loaded_groups_info() const {
    std::lock_guard<std::recursive_mutex> lock(_mutex);
    std::vector<GroupInfo> result;
    for (const auto& g : _groups) {
        if (g) {
            std::string name = g->desc().empty() ? g->group_id() : g->desc();
            result.push_back({g->group_id(), name, g->get_labels()});
        }
    }
    return result;
}

bool InferManager::init(const std::string& model_path, const std::string& label_path) {
    std::lock_guard<std::recursive_mutex> lock(_mutex);
    if (_groups.empty()) {
        register_models(*this);
    }

    int success_count = 0;
    for (auto& group : _groups) {
        if (!group) continue;
        if (group->is_initialized()) {
            success_count++;
            continue;
        }

        if (!group->init(model_path, label_path)) {
            continue;
        }

        printf("[InferManager] 推理组 [%s] 成功加载并就绪 (包含 %zu 个 step)\n",
               group->group_id().c_str(), group->step_count());
        fflush(stdout);
        success_count++;
    }

    return success_count > 0;
}

void InferManager::release() {
    std::lock_guard<std::recursive_mutex> lock(_mutex);
    for (auto& group : _groups) {
        if (group) {
            group->release();
        }
    }
    _groups.clear();
    std::lock_guard<std::mutex> lock_ch(_channel_mutex);
    _channel_groups.clear();
    _model_files.clear();
}

bool InferManager::is_initialized() const {
    std::lock_guard<std::recursive_mutex> lock(_mutex);
    for (const auto& group : _groups) {
        if (group && group->is_initialized()) {
            return true;
        }
    }
    return false;
}

std::shared_ptr<InferGroup> InferManager::group_at(size_t index) const {
    std::lock_guard<std::recursive_mutex> lock(_mutex);
    return (index < _groups.size()) ? _groups[index] : nullptr;
}

size_t InferManager::group_count() const {
    std::lock_guard<std::recursive_mutex> lock(_mutex);
    return _groups.size();
}

std::shared_ptr<InferManager> InferManager::clone(uint32_t core_mask) {
    std::lock_guard<std::recursive_mutex> lock(_mutex);
    auto cloned = std::make_shared<InferManager>(false);
    for (const auto& group : _groups) {
        if (!group || !group->is_initialized()) continue;
        auto ch_model = group->clone(core_mask);
        auto ch_group = std::dynamic_pointer_cast<InferGroup>(ch_model);
        if (ch_group) {
            cloned->register_group(ch_group);
        }
    }
    {
        std::lock_guard<std::mutex> lock_ch(_channel_mutex);
        for (const auto& pair : _channel_groups) {
            cloned->bind_channel(pair.first, pair.second);
        }
        for (const auto& pair : _model_files) {
            cloned->bind_model_file(pair.first, pair.second);
        }
    }
    return cloned;
}

void* InferManager::input_buf(const std::string& group_id) const {
    auto g = get_group(group_id);
    return g ? g->input_buf() : nullptr;
}

int InferManager::input_width(const std::string& group_id) const {
    auto g = get_group(group_id);
    return g ? g->model_width() : 0;
}

int InferManager::input_height(const std::string& group_id) const {
    auto g = get_group(group_id);
    return g ? g->model_height() : 0;
}

int InferManager::input_channel(const std::string& group_id) const {
    auto g = get_group(group_id);
    return g ? g->model_channel() : 3;
}

const char* InferManager::get_label_name(int cls_id) const {
    (void)cls_id;
    return nullptr;
}

const char* InferManager::get_label_name(const std::string& group_id, int cls_id) const {
    auto g = get_group(group_id);
    if (g) {
        return g->get_label_name(cls_id);
    }
    return nullptr;
}
