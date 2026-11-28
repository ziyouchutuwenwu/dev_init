#include "ai/infer/plate_det/plate_det_infer.h"

PlateDetInfer::PlateDetInfer(const std::string& model_id,
                             const std::string& model_path,
                             float conf_thresh,
                             float nms_thresh)
    : Yolo11Infer(model_id,
                  model_path,
                  conf_thresh,
                  nms_thresh) {
}

std::shared_ptr<IModelInfer> PlateDetInfer::clone(uint32_t core_mask) {
    auto base_cloned = Yolo11Infer::clone(core_mask);
    if (!base_cloned) {
        return std::make_shared<PlateDetInfer>(_model_id, _model_path, _conf_thresh, _nms_thresh);
    }
    return base_cloned;
}
