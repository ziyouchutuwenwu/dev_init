#ifndef INFER_GROUP_H
#define INFER_GROUP_H

#include "ai/infer_manager/model_infer.h"
#include "ai/infer_manager/detect_result.h"
#include <memory>
#include <string>
#include <vector>
#include <mutex>
#include <initializer_list>

class InferGroup : public IModelInfer, public std::enable_shared_from_this<InferGroup> {
public:
    explicit InferGroup(const std::string& group_id, const std::string& desc = "");
    InferGroup(const std::string& group_id, std::vector<std::shared_ptr<IModelInfer>> steps);
    InferGroup(const std::string& group_id, std::initializer_list<std::shared_ptr<IModelInfer>> steps);
    InferGroup(const std::string& group_id, std::shared_ptr<IModelInfer> single_step);
    ~InferGroup() override;

    InferGroup& step(std::shared_ptr<IModelInfer> step_model);

    template <typename T, typename... Args>
    InferGroup& step(Args&&... args) {
        return step(std::make_shared<T>(std::forward<Args>(args)...));
    }

    const std::string& group_id() const { return _group_id; }
    const std::string& model_id() const override { return _group_id; }
    const std::string& desc() const { return _desc; }
    void set_desc(const std::string& desc) { _desc = desc; }

    bool init(const std::string& model_path = "", const std::string& label_path = "") override;
    void release() override;
    bool is_initialized() const override;

    int model_width() const override;
    int model_height() const override;
    int model_channel() const override;

    const char* get_label_name(int cls_id) override;
    const std::vector<std::string>& get_labels() const override;

    void* input_buf() override;

    bool infer(image_buffer_t& img, DetectResult& result) override;
    bool infer_frame(const std::shared_ptr<VpuDecoder::FrameBuffer>& frame, DetectResult& result) override;

    std::shared_ptr<IModelInfer> clone(uint32_t core_mask = 0) override;

    const std::vector<std::shared_ptr<IModelInfer>>& steps() const { return _steps; }
    size_t step_count() const { return _steps.size(); }
    std::shared_ptr<IModelInfer> step_at(size_t index) const {
        return index < _steps.size() ? _steps[index] : nullptr;
    }

private:
    bool process_stage_from_frame(size_t stage_idx,
                                 const std::shared_ptr<VpuDecoder::FrameBuffer>& frame,
                                 YoloDetectObject& obj);
    bool process_stage_from_img(size_t stage_idx,
                                image_buffer_t& img,
                                YoloDetectObject& obj);

    mutable std::recursive_mutex _mutex;
    std::string _group_id;
    std::string _desc;
    std::vector<std::shared_ptr<IModelInfer>> _steps;
    mutable std::shared_ptr<std::vector<std::string>> _cached_labels;
};

#endif
