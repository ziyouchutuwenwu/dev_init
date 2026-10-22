#ifndef AI_MODEL_DETECT_OBJECT_H
#define AI_MODEL_DETECT_OBJECT_H

#include <string>

struct YoloDetectObject {
    std::string model_name;
    int class_id = 0;
    std::string label;
    std::string text;
    float score = 0.0f;
    int box[4] = {0, 0, 0, 0};
    float rel_box[4] = {0.0f, 0.0f, 0.0f, 0.0f};
};

using DetectObject = YoloDetectObject;

#endif // AI_MODEL_DETECT_OBJECT_H
