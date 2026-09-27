#ifndef INFER_PIPELINE_H
#define INFER_PIPELINE_H

#include "ai/model/model_infer.h"
#include "ai/pipeline/detect_result.h"
#include <string>
#include <memory>
#include <vector>
#include <utility>

class InferPipeline {
public:
    explicit InferPipeline(bool auto_register = true);
    explicit InferPipeline(std::shared_ptr<IModelInfer> model);
    ~InferPipeline();

    bool init(const std::string& model_path = "", const std::string& label_path = "");
    void release();
    bool is_initialized() const;

    InferPipeline& add(std::shared_ptr<IModelInfer> model);

    template <typename T, typename... Args>
    InferPipeline& add(Args&&... args) {
        return add(std::make_shared<T>(std::forward<Args>(args)...));
    }

    void clear();

    const std::vector<std::shared_ptr<IModelInfer>>& models() const { return _models; }
    std::shared_ptr<IModelInfer> model(size_t index = 0) const {
        return (index < _models.size()) ? _models[index] : nullptr;
    }
    size_t model_count() const { return _models.size(); }

    std::shared_ptr<InferPipeline> clone(uint32_t core_mask = 0);

    void* input_buf() const;
    int input_width() const;
    int input_height() const;
    int input_channel() const;
    const char* get_label_name(int cls_id) const;

    bool process(image_buffer_t& img, DetectResult& result);

private:
    std::vector<std::shared_ptr<IModelInfer>> _models;
};

#endif
