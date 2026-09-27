cmake_minimum_required(VERSION 3.10)
project(detector C CXX)

set(CMAKE_C_STANDARD 99)
set(CMAKE_CXX_STANDARD 14)

include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${CMAKE_CURRENT_SOURCE_DIR}/include/ai
    ${CMAKE_CURRENT_SOURCE_DIR}/include/ai/register
    ${CMAKE_CURRENT_SOURCE_DIR}/include/ai/pipeline
    ${CMAKE_CURRENT_SOURCE_DIR}/include/ai/model
    ${CMAKE_CURRENT_SOURCE_DIR}/include/ai/yolo11
    ${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/model_license/include
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
    src/ai/pipeline/infer_pipeline.cc
    src/ai/yolo11/yolo11_infer.cc
    src/ai/yolo11/postprocess.cc
    src/hardware/npu_infer.cc
    src/hardware/npu_worker_pool.cc
    src/hardware/vpu_decoder.cc
    src/hardware/channel_decoder.cc
    src/security/model_decrypter.cc
    src/security/model_memory.cc
    src/security/license_validator.cc
    3rdparty/rknn_model_zoo/utils/image_utils.c
    3rdparty/rknn_model_zoo/utils/file_utils.c
    3rdparty/rknn_model_zoo/utils/image_drawing.c
)

set(LIBRKNNRT "${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/rknn_model_zoo/3rdparty/rknpu2/Linux/aarch64/librknnrt.so")
set(LIBRGA    "${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/rknn_model_zoo/3rdparty/librga/Linux/aarch64/librga.so")
set(LIBMODEL_LICENSE "${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/model_license/lib/libmodel_license.a")

if(NOT EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/model_license/include/model_license.h" OR NOT EXISTS "${LIBMODEL_LICENSE}")
    message(STATUS "未检测到 model_license 产物，正在自动通过 encrypter 构建并同步...")
    execute_process(
        COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/../encrypter/build.sh" aarch64
        WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/../encrypter"
    )
endif()

add_library(detector_static STATIC ${SRCS})

add_executable(detect_cli src/detect_cli.cc)
target_link_libraries(detect_cli detector_static ${LIBRKNNRT} ${LIBRGA} ${LIBMODEL_LICENSE} pthread dl m)
set_target_properties(detect_cli PROPERTIES BUILD_WITH_INSTALL_RPATH TRUE)
set_target_properties(detect_cli PROPERTIES INSTALL_RPATH "$ORIGIN:$ORIGIN/lib:/usr/local/lib:/usr/lib")

add_executable(detector src/main.cc src/detector.cc)
target_link_libraries(detector detector_static ${LIBRKNNRT} ${LIBRGA} ${LIBMODEL_LICENSE} pthread dl m)
set_target_properties(detector PROPERTIES BUILD_WITH_INSTALL_RPATH TRUE)
set_target_properties(detector PROPERTIES INSTALL_RPATH "$ORIGIN:$ORIGIN/lib:/usr/local/lib:/usr/lib")
