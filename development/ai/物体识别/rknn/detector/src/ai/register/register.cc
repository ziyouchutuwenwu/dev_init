#include "ai/register/register.h"
#include "ai/infer_manager/infer_manager.h"
#include "ai/infer/yolo11/yolo11_infer.h"
#include "ai/infer/lprnet/lprnet_infer.h"

void register_single_infers(InferManager& manager) {
    manager.register_infer<Yolo11Infer>("industry", "model/industry.enc");
    manager.register_infer<Yolo11Infer>("safety_ppe", "model/safety_ppe.enc");
    manager.register_infer<Yolo11Infer>("forklift_collision", "model/forklift_yolo11s.enc");
    manager.register_infer<Yolo11Infer>("steel_defect", "model/steel_defect_yolo11n.enc");
    manager.register_infer<Yolo11Infer>("tile_defect", "model/tile_defect_yolo11l.enc");
    manager.register_infer<Yolo11Infer>("yolo_raw", "model/yolo_raw.enc");
}

void register_pipelines(InferManager& manager) {
    auto plate_det = std::make_shared<Yolo11Infer>("plate", "model/license_plate.enc");
    auto plate_rec = std::make_shared<LprNetInfer>("lprnet", "model/lprnet.enc");
    manager.register_pipeline("license_plate", plate_det, plate_rec);
}

void register_models(InferManager& manager) {
    register_single_infers(manager);
    register_pipelines(manager);
}