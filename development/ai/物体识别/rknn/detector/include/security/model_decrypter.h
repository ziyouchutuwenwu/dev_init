#ifndef MODEL_DECRYPTER_H
#define MODEL_DECRYPTER_H

#include <string>
#include <mutex>
#include "rknn_api.h"
#include "ai/model/model_infer.h"
#include "security/switcher.h"
#include "security/model_memory.h"

class ModelDecrypter {
public:
    static ModelDecrypter& instance();

    const char* const* get_labels_list(const std::string& model_id = "");

    std::string find_model_path(const std::string& user_path = "", const std::string& default_model_name = "");

    bool load_model_memory(const std::string& model_path, ModelMemory& out_buf, const std::string& default_model_name = "");

    int init_model(const std::string& model_path, rknn_app_context_t* app_ctx, const std::string& model_tag = "RKNN", const std::string& default_model_name = "");

    std::string get_encrypted_model_id(const std::string& model_path);

    int init_yolo11_model(const std::string& model_path, rknn_app_context_t* app_ctx) {
        return init_model(model_path, app_ctx, "YOLO11", "yolo11");
    }

    int init_yolov8_model(const std::string& model_path, rknn_app_context_t* app_ctx) {
        return init_model(model_path, app_ctx, "YOLOv8", "yolov8");
    }

private:
    ModelDecrypter() = default;
    ~ModelDecrypter() = default;

    ModelDecrypter(const ModelDecrypter&) = delete;
    ModelDecrypter& operator=(const ModelDecrypter&) = delete;

    std::string resolve_file_path(const std::string& path);

    std::mutex _mutex;
};

#endif
