#ifndef AI_MODEL_DETECT_OBJECT_H
#define AI_MODEL_DETECT_OBJECT_H

#include <string>
#include <vector>

struct YoloDetectObject {
    std::string model_id;
    int class_id = 0;
    std::string label;
    std::string text;
    float score = 0.0f;
    int box[4] = {0, 0, 0, 0};
    float rel_box[4] = {0.0f, 0.0f, 0.0f, 0.0f};
    std::vector<float> keypoints;
};

using DetectObject = YoloDetectObject;

#endif
