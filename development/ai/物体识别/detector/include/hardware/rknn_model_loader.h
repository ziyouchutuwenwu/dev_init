#ifndef RKNN_MODEL_LOADER_H
#define RKNN_MODEL_LOADER_H

#include "ai/infer_manager/rknn_app_context.h"
#include <string>
#include <vector>
#include <unordered_map>
#include <mutex>

class RknnModelLoader {
public:
    static RknnModelLoader& instance();

    void bind_model_file(const std::string& model_id, const std::string& file_path);
    std::string get_bound_model_file(const std::string& model_id) const;

    std::string find_model_path(const std::string& user_path, const std::string& default_model_id = "");
    int init_model(const std::string& model_path, rknn_app_context_t* app_ctx,
                   const std::string& model_tag = "RKNN", const std::string& default_model_id = "");

    const char* const* get_labels_list(const std::string& model_id);

private:
    RknnModelLoader() = default;
    mutable std::mutex _mutex;
    std::unordered_map<std::string, std::string> _bound_model_files;
};

#endif
