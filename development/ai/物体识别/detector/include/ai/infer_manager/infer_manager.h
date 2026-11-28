#ifndef INFER_MANAGER_H
#define INFER_MANAGER_H

#include "ai/infer_manager/model_infer.h"
#include "ai/group/infer_group.h"
#include <string>
#include <vector>
#include <memory>
#include <mutex>
#include <atomic>
#include <unordered_map>
#include <utility>
#include <initializer_list>

class InferManager : public std::enable_shared_from_this<InferManager> {
public:
    explicit InferManager(bool auto_register = true);
    ~InferManager();

    InferManager(const InferManager&) = delete;
    InferManager& operator=(const InferManager&) = delete;
    InferManager(InferManager&&) = default;
    InferManager& operator=(InferManager&&) = default;

    bool bind_model_file(const std::string& model_id, const std::string& file_path);
    bool bind_model_id(const std::string& model_id, const std::string& file_path) {
        return bind_model_file(model_id, file_path);
    }
    std::string get_model_file(const std::string& model_id) const;

    // 流式 Group 注册接口：manager.register_group("gen", "通用检测").step(gen_infer);
    InferGroup& register_group(const std::string& group_id, const std::string& desc = "");
    InferGroup& reg(const std::string& group_id, const std::string& desc = "") { return register_group(group_id, desc); }
    InferGroup& group(const std::string& group_id, const std::string& desc = "") { return register_group(group_id, desc); }

    bool register_group(std::shared_ptr<InferGroup> group);
    bool register_group(const std::string& group_id, std::shared_ptr<IModelInfer> single_infer);
    bool register_group(const std::string& group_id, const std::vector<std::shared_ptr<IModelInfer>>& steps);
    bool register_group(const std::string& group_id, std::initializer_list<std::shared_ptr<IModelInfer>> steps);

    template <typename... Args>
    bool register_group(const std::string& group_id,
                        std::shared_ptr<IModelInfer> first,
                        std::shared_ptr<IModelInfer> second,
                        Args&&... rest) {
        std::vector<std::shared_ptr<IModelInfer>> steps = {first, second, std::forward<Args>(rest)...};
        return register_group(group_id, steps);
    }

    template <typename T, typename... Args>
    bool register_group(const std::string& group_id, Args&&... args) {
        return register_group(group_id, std::make_shared<T>(group_id, std::forward<Args>(args)...));
    }

    template <typename... Args>
    bool register_chain(const std::string& id, Args&&... args) {
        return register_group(id, std::forward<Args>(args)...);
    }

    bool bind_channel(int channel_id, const std::string& group_id);
    bool unbind_channel(int channel_id);
    bool is_channel_bound(int channel_id) const;
    std::string get_channel_group(int channel_id) const;
    std::string get_channel_chain(int channel_id) const { return get_channel_group(channel_id); }

    std::shared_ptr<InferGroup> get_group_for_channel(int channel_id);
    std::shared_ptr<InferGroup> get_group(const std::string& group_id = "") const;
    std::shared_ptr<InferGroup> get_chain(const std::string& chain_id = "") const { return get_group(chain_id); }
    std::shared_ptr<InferGroup> get_chain_by_channel(int channel_id) { return get_group_for_channel(channel_id); }

    std::vector<std::string> get_registered_groups() const;
    std::vector<std::string> get_registered_chains() const { return get_registered_groups(); }

    bool init(const std::string& model_path = "", const std::string& label_path = "");
    void release();

    bool is_initialized() const;
    bool is_ready() const { return is_initialized(); }

    std::shared_ptr<IModelInfer> get_model(const std::string& model_id = "") const {
        return get_group(model_id);
    }

    std::shared_ptr<InferGroup> group_at(size_t index) const;
    size_t group_count() const;
    struct GroupInfo {
        std::string id;
        std::string name;
        std::vector<std::string> classes;
    };
    std::vector<GroupInfo> get_loaded_groups_info() const;
    std::vector<std::string> get_loaded_models() const {
        return get_registered_groups();
    }

    std::shared_ptr<InferManager> clone(uint32_t core_mask = 0);

    const char* get_label_name(int cls_id) const;
    const char* get_label_name(const std::string& group_id, int cls_id) const;

    void* input_buf(const std::string& group_id = "") const;
    int input_width(const std::string& group_id = "") const;
    int input_height(const std::string& group_id = "") const;
    int input_channel(const std::string& group_id = "") const;

    const std::vector<std::shared_ptr<InferGroup>>& groups() const { return _groups; }

private:
    mutable std::recursive_mutex _mutex;
    std::vector<std::shared_ptr<InferGroup>> _groups;
    mutable std::mutex _channel_mutex;
    std::unordered_map<int, std::string> _channel_groups;
    std::unordered_map<std::string, std::string> _model_files;
    std::atomic<uint32_t> _auto_switch_counter{0};
};

using ModelManager = InferManager;

#endif
