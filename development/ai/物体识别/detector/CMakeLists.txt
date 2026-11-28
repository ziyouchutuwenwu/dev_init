cmake_minimum_required(VERSION 3.10)
project(detector C CXX)

set(CMAKE_C_STANDARD 99)
set(CMAKE_CXX_STANDARD 14)

include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${CMAKE_CURRENT_SOURCE_DIR}/include/ai
    ${CMAKE_CURRENT_SOURCE_DIR}/include/ai/register
    ${CMAKE_CURRENT_SOURCE_DIR}/include/ai/infer_manager
    ${CMAKE_CURRENT_SOURCE_DIR}/include/ai/infer
    ${CMAKE_CURRENT_SOURCE_DIR}/include/ai/infer/yolo11
    ${CMAKE_CURRENT_SOURCE_DIR}/include/ai/infer/plate_det
    ${CMAKE_CURRENT_SOURCE_DIR}/include/ai/infer/lprnet
    ${CMAKE_CURRENT_SOURCE_DIR}/include/ai/group
    ${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/model_label/include
    ${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/mpp/inc
    ${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/rknn_model_zoo/3rdparty/rknpu2/include
    ${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/rknn_model_zoo/3rdparty/librga/include
    ${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/rknn_model_zoo/3rdparty/stb_image
    ${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/rknn_model_zoo/utils
)

add_definitions(-DENABLE_RKNN -DDISABLE_LIBJPEG)

set(SRCS
    src/engine/engine.cc
    src/channel/channel.cc
    src/channel/channel_manager.cc
    src/ai/register/register.cc
    src/ai/infer_manager/infer_manager.cc
    src/ai/infer/yolo11/yolo11_infer.cc
    src/ai/infer/yolo11/postprocess.cc
    src/ai/infer/plate_det/plate_det_infer.cc
    src/ai/infer/lprnet/lprnet_infer.cc
    src/ai/infer/lprnet/postprocess.cc
    src/ai/group/infer_group.cc
    src/hardware/npu_infer.cc
    src/hardware/npu_channel_context.cc
    src/hardware/npu_worker_pool.cc
    src/hardware/vpu_decoder.cc
    src/hardware/frame_buffer.cc
    src/hardware/channel_decoder.cc
    src/hardware/rknn_model_loader.cc
    3rdparty/rknn_model_zoo/utils/image_utils.c
    3rdparty/rknn_model_zoo/utils/file_utils.c
    3rdparty/rknn_model_zoo/utils/image_drawing.c
)

set(LIBRKNNRT "${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/rknn_model_zoo/3rdparty/rknpu2/Linux/aarch64/librknnrt.so")
set(LIBRGA    "${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/rknn_model_zoo/3rdparty/librga/Linux/aarch64/librga.so")
set(LIBMODEL_LABEL "${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/model_label/lib/libmodel_label.a")

if(NOT EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/model_label/include/model_label.h" OR NOT EXISTS "${LIBMODEL_LABEL}")
    message(FATAL_ERROR "未检测到 model_label 产物 (libmodel_label.a / model_label.h)，请先构建 model_label 并同步依赖产物！")
endif()

add_library(detector_static STATIC ${SRCS})

add_executable(detect_cli src/detect_cli.cc)
target_link_libraries(detect_cli detector_static ${LIBRKNNRT} ${LIBRGA} ${LIBMODEL_LABEL} pthread dl m)
set_target_properties(detect_cli PROPERTIES BUILD_WITH_INSTALL_RPATH TRUE)
set_target_properties(detect_cli PROPERTIES INSTALL_RPATH "$ORIGIN:$ORIGIN/lib:/usr/local/lib:/usr/lib")

add_executable(detector src/main.cc src/detector.cc)
target_link_libraries(detector detector_static ${LIBRKNNRT} ${LIBRGA} ${LIBMODEL_LABEL} pthread dl m)
set_target_properties(detector PROPERTIES BUILD_WITH_INSTALL_RPATH TRUE)
set_target_properties(detector PROPERTIES INSTALL_RPATH "$ORIGIN:$ORIGIN/lib:/usr/local/lib:/usr/lib")
