#ifndef PLATE_DET_INFER_H
#define PLATE_DET_INFER_H

#include "ai/infer/yolo11/yolo11_infer.h"

class PlateDetInfer : public Yolo11Infer {
public:
    explicit PlateDetInfer(const std::string& model_id = "license_plate",
                           const std::string& model_path = "",
                           float conf_thresh = -1.0f,
                           float nms_thresh = -1.0f);
    virtual ~PlateDetInfer() = default;

    std::shared_ptr<IModelInfer> clone(uint32_t core_mask = 0) override;
};

#endif
