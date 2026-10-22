#ifndef INFER_MANAGER_H
#define INFER_MANAGER_H

#include "ai/infer_manager/model_infer.h"
#include <string>
#include <vector>
#include <memory>
#include <mutex>
#include <utility>

/**
 * @brief InferManager 统一管理系统中加载的各类 AI 算法推理器 (Infer) 与流水线 (Pipeline)。
 * 
 * 核心职责：
 * 1. 注册与管理多个单模型推理器 (Infer) 与多阶段组合流水线 (Pipeline)；
 * 2. 支持多核心（RK3588/RK3576 NPU）通过 rknn_dup_context 共享物理权重的模型克隆；
 * 3. 根据通道需求（Channel ID / Task Name / Model Name）快速路由、获取指定推理实例；
 * 4. 容错加载各垂直模型，防止单一模型文件异常导致全局服务瘫痪。
 */
class InferManager : public std::enable_shared_from_this<InferManager> {
public:
    explicit InferManager(bool auto_register = true);
    ~InferManager();

    InferManager(const InferManager&) = delete;
    InferManager& operator=(const InferManager&) = delete;
    InferManager(InferManager&&) = default;
    InferManager& operator=(InferManager&&) = default;

    /**
     * @brief 注册单模型推理器 (Infer)
     */
    bool register_infer(std::shared_ptr<IModelInfer> infer);

    template <typename T, typename... Args>
    bool register_infer(Args&&... args) {
        return register_infer(std::make_shared<T>(std::forward<Args>(args)...));
    }

    /**
     * @brief 注册通用多阶段流水线 (Pipeline)
     * 支持传入 vector、initializer_list，或任意数量阶段的推理器指针 (如 2阶段、3阶段等)
     */
    bool register_pipeline(const std::string& name,
                           const std::vector<std::shared_ptr<IModelInfer>>& stages);

    bool register_pipeline(const std::string& name,
                           std::initializer_list<std::shared_ptr<IModelInfer>> stages) {
        return register_pipeline(name, std::vector<std::shared_ptr<IModelInfer>>(stages));
    }

    template <typename... Args>
    bool register_pipeline(const std::string& name,
                           std::shared_ptr<IModelInfer> first,
                           Args&&... rest) {
        std::vector<std::shared_ptr<IModelInfer>> stages = {first, std::forward<Args>(rest)...};
        return register_pipeline(name, stages);
    }

    /**
     * @brief 兼容原有 register_model 别名
     */
    bool register_model(std::shared_ptr<IModelInfer> model) {
        return register_infer(model);
    }

    template <typename T, typename... Args>
    bool register_model(Args&&... args) {
        return register_infer<T>(std::forward<Args>(args)...);
    }

    /**
     * @brief 兼容流式链式调用 add
     */
    template <typename T, typename... Args>
    InferManager& add(Args&&... args) {
        register_infer<T>(std::forward<Args>(args)...);
        return *this;
    }
    InferManager& add(std::shared_ptr<IModelInfer> model) {
        register_infer(model);
        return *this;
    }

    /**
     * @brief 初始化所有已注册的推理器与流水线
     * @param model_path 统一覆盖路径 (留空则使用模型自身默认配置)
     * @param label_path 统一覆盖标签路径 (留空则使用模型自身默认配置)
     * @return true 至少成功初始化了 1 个模型；false 全部初始化失败
     */
    bool init(const std::string& model_path = "", const std::string& label_path = "");

    /**
     * @brief 释放所有资源
     */
    void release();

    /**
     * @brief 检查是否至少有一个模型处于就绪状态
     */
    bool is_initialized() const;
    bool is_ready() const { return is_initialized(); }

    /**
     * @brief 根据标识符获取推理实例（单模型或流水线统一获取）
     */
    std::shared_ptr<IModelInfer> get_model(const std::string& name = "") const;
    std::shared_ptr<IModelInfer> get_infer(const std::string& name = "") const { return get_model(name); }
    std::shared_ptr<IModelInfer> get_pipeline(const std::string& name = "") const { return get_model(name); }

    std::shared_ptr<IModelInfer> find_model(const std::string& name) const {
        return get_model(name);
    }

    std::shared_ptr<IModelInfer> model(size_t index = 0) const;
    size_t model_count() const;
    std::vector<std::string> get_loaded_models() const;

    /**
     * @brief 克隆所有就绪模型到指定的 NPU 硬件核心 (Core Mask)
     */
    std::shared_ptr<InferManager> clone(uint32_t core_mask = 0);

    const char* get_label_name(int cls_id) const;
    const char* get_label_name(const std::string& model_name, int cls_id) const;

    void* input_buf(const std::string& model_name = "") const;
    int input_width(const std::string& model_name = "") const;
    int input_height(const std::string& model_name = "") const;
    int input_channel(const std::string& model_name = "") const;

    const std::vector<std::shared_ptr<IModelInfer>>& models() const { return _models; }

private:
    mutable std::recursive_mutex _mutex;
    std::vector<std::shared_ptr<IModelInfer>> _models;
};

// 保持别名兼容
using ModelManager = InferManager;

#endif // INFER_MANAGER_H
