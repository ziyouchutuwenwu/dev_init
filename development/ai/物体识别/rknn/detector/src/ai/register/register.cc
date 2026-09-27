#include "ai/register/register.h"
#include "ai/yolo11/yolo11_infer.h"

void register_models(InferPipeline& pipeline) {
    pipeline.add<Yolo11Infer>();
}
