#ifndef YOLO11_CONST_H
#define YOLO11_CONST_H

#include "security/switcher.h"

#if ENABLE_SECURITY
  #define MODEL_PATH_YOLO11     "yolo11.enc"
#else
  #define MODEL_PATH_YOLO11     "yolo11.rknn"
#endif

#endif