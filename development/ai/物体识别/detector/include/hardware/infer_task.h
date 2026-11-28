#pragma once

#include <string>
#include <memory>
#include <functional>
#include <cstdint>
#include "ai/infer_manager/detect_result.h"
#include "hardware/vpu_decoder.h"

struct InferTask {
    int channel_id = -1;
    std::string model_id;
    std::shared_ptr<VpuDecoder::FrameBuffer> frame;
    std::function<void(int ch, uint64_t frame_idx, int64_t pts_ms, int orig_w, int orig_h, const DetectResult& result)> callback;
};
