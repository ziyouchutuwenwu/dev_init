#ifndef AI_INFER_PIPELINE_H
#define AI_INFER_PIPELINE_H

#include "ai/infer_manager/model_infer.h"
#include "ai/infer_manager/detect_result.h"
#include <memory>
#include <string>
#include <vector>
#include <mutex>
#include <initializer_list>

/**
 * @brief 通用多阶段推理流水线 (InferPipeline)
 * 
 * 适用于任何 N 阶段 (N >= 1) 级联与组合推理场景：
 * - Stage 0: 初始检测/定位 (整帧/整图推理，产出候选目标)
 * - Stage 1 .. N-1: 级联推理 (依次对候选目标进行 ROI 裁剪 ➔ 缩放 ➔ 下阶段推理 ➔ 属性回填或区域精细化)
 * 
 * 完全不涉及具体业务，不绑定车牌、人脸或任何垂直行业。
 */
class InferPipeline : public IModelInfer, public std::enable_shared_from_this<InferPipeline> {
public:
    InferPipeline(const std::string& name,
                  std::vector<std::shared_ptr<IModelInfer>> stages = {});
    InferPipeline(const std::string& name,
                  std::initializer_list<std::shared_ptr<IModelInfer>> stages);
    InferPipeline(const std::string& name,
                  std::shared_ptr<IModelInfer> first_stage,
                  std::shared_ptr<IModelInfer> second_stage);
    ~InferPipeline() override;

    const std::string& name() const override { return _name; }

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

    // 动态添加/管理流水线阶段
    InferPipeline& add_stage(std::shared_ptr<IModelInfer> stage);
    const std::vector<std::shared_ptr<IModelInfer>>& stages() const { return _stages; }
    size_t stage_count() const { return _stages.size(); }
    std::shared_ptr<IModelInfer> stage(size_t index) const {
        return index < _stages.size() ? _stages[index] : nullptr;
    }

private:
    bool process_stage_from_frame(size_t stage_idx,
                                 const std::shared_ptr<VpuDecoder::FrameBuffer>& frame,
                                 YoloDetectObject& obj);
    bool process_stage_from_img(size_t stage_idx,
                               image_buffer_t& img,
                               YoloDetectObject& obj);

    std::recursive_mutex _mutex;
    std::string _name;
    std::vector<std::shared_ptr<IModelInfer>> _stages;
};

// 保持别名兼容
using Pipeline = InferPipeline;

#endif // AI_INFER_PIPELINE_H
