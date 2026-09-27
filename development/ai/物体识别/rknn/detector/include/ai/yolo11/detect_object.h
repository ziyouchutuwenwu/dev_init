#ifndef YOLO11_DETECT_OBJECT_H
#define YOLO11_DETECT_OBJECT_H

#include <string>

struct YoloDetectObject {
    int class_id;
    std::string label;
    float score;
    int box[4];
    float rel_box[4];
};

#endif
