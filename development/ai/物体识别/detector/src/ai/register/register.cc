#include "ai/register/register.h"
#include "ai/infer_manager/infer_manager.h"
#include "ai/infer/yolo11/yolo11_infer.h"
#include "ai/infer/plate_det/plate_det_infer.h"
#include "ai/infer/lprnet/lprnet_infer.h"

void bind_model_files(InferManager& manager) {
    manager.bind_model_id("gen", "model/gen.rknn");
    manager.bind_model_id("industry", "model/industry.rknn");
    manager.bind_model_id("anfang", "model/anfang.rknn");
    manager.bind_model_id("chache", "model/chache.rknn");
    manager.bind_model_id("license_plate", "model/license_plate.rknn");
    manager.bind_model_id("lprnet", "model/lprnet.rknn");
}

void register_groups(InferManager& manager) {
    manager.register_group("gen", "通用检测")
           .step(std::make_shared<Yolo11Infer>("gen"));

    manager.register_group("industry", "工业检测")
           .step(std::make_shared<Yolo11Infer>("industry"));

    manager.register_group("anfang", "安防")
           .step(std::make_shared<Yolo11Infer>("anfang"));

    manager.register_group("chache", "叉车")
           .step(std::make_shared<Yolo11Infer>("chache"));

    manager.register_group("chepai", "车牌")
           .step(std::make_shared<PlateDetInfer>("license_plate"))
           .step(std::make_shared<LprNetInfer>("lprnet"));
}

void register_models(InferManager& manager) {
    bind_model_files(manager);
    register_groups(manager);
}
