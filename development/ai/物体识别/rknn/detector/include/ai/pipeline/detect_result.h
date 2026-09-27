#ifndef DETECT_RESULT_H
#define DETECT_RESULT_H

#include "ai/yolo11/detect_object.h"
#include <vector>
#include <cstdint>

struct DetectResult {
    int orig_width = 0;
    int orig_height = 0;
    uint64_t frame_idx = 0;
    int64_t pts_ms = 0;
    std::vector<YoloDetectObject> objects;
};

#endif