#include "hardware/rknn_model_loader.h"
#include "utils/path_utils.h"
#include "file_utils.h"
#include "model_label.h"
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <vector>

RknnModelLoader& RknnModelLoader::instance() {
    static RknnModelLoader s_instance;
    return s_instance;
}

void RknnModelLoader::bind_model_file(const std::string& model_id, const std::string& file_path) {
    if (model_id.empty() || file_path.empty()) return;
    std::lock_guard<std::mutex> lock(_mutex);
    _bound_model_files[model_id] = file_path;
}

std::string RknnModelLoader::get_bound_model_file(const std::string& model_id) const {
    if (model_id.empty()) return "";
    std::lock_guard<std::mutex> lock(const_cast<std::mutex&>(_mutex));
    auto it = _bound_model_files.find(model_id);
    return (it != _bound_model_files.end()) ? it->second : "";
}

std::string RknnModelLoader::find_model_path(const std::string& user_path, const std::string& default_model_id) {
    auto check_exist = [](const std::string& p) -> std::string {
        if (p.empty()) return "";
        std::string resolved = PathUtils::resolve_path(p);
        if (!resolved.empty() && access(resolved.c_str(), R_OK) == 0) return resolved;
        return "";
    };

    if (!user_path.empty()) {
        std::string r = check_exist(user_path);
        if (!r.empty()) return r;
        return user_path;
    }
    if (!default_model_id.empty()) {
        std::string bound = get_bound_model_file(default_model_id);
        if (!bound.empty()) {
            std::string r = check_exist(bound);
            if (!r.empty()) return r;
        }
        std::string r = check_exist(default_model_id);
        if (!r.empty()) return r;
        r = check_exist("model/" + default_model_id + ".rknn");
        if (!r.empty()) return r;
        return default_model_id;
    }
    return "";
}

const char* const* RknnModelLoader::get_labels_list(const std::string& model_id) {
    if (model_id.empty()) return nullptr;
    return ::get_model_labels_list(model_id.c_str());
}

int RknnModelLoader::init_model(const std::string& model_path, rknn_app_context_t* app_ctx,
                               const std::string& model_tag, const std::string& default_model_id) {
    if (!app_ctx) return -1;

    std::string resolved = find_model_path(model_path, default_model_id);
    if (resolved.empty() || access(resolved.c_str(), R_OK) != 0) {
        fprintf(stderr, "[%s] 错误: 找不到模型文件: %s\n", model_tag.c_str(), resolved.c_str());
        return -1;
    }

    char* model_data = nullptr;
    int model_size = read_data_from_file(resolved.c_str(), &model_data);
    if (model_size <= 0 || !model_data) {
        fprintf(stderr, "[%s] 错误: 读取模型文件失败: %s\n", model_tag.c_str(), resolved.c_str());
        return -1;
    }

    rknn_context ctx = 0;
    int ret = rknn_init(&ctx, model_data, static_cast<uint32_t>(model_size), 0, NULL);
    free(model_data);

    if (ret < 0) {
        fprintf(stderr, "[%s] rknn_init 失败! ret=%d\n", model_tag.c_str(), ret);
        return -1;
    }

    rknn_input_output_num io_num;
    ret = rknn_query(ctx, RKNN_QUERY_IN_OUT_NUM, &io_num, sizeof(io_num));
    if (ret != RKNN_SUCC || io_num.n_input == 0 || io_num.n_output == 0) {
        fprintf(stderr, "[%s] rknn io_num 异常\n", model_tag.c_str());
        rknn_destroy(ctx);
        return -1;
    }

    std::vector<rknn_tensor_attr> input_attrs(io_num.n_input);
    for (uint32_t i = 0; i < io_num.n_input; i++) {
        input_attrs[i].index = i;
        ret = rknn_query(ctx, RKNN_QUERY_INPUT_ATTR, &(input_attrs[i]), sizeof(rknn_tensor_attr));
        if (ret != RKNN_SUCC) {
            fprintf(stderr, "[%s] rknn_query input attr 失败!\n", model_tag.c_str());
            rknn_destroy(ctx);
            return -1;
        }
    }

    std::vector<rknn_tensor_attr> output_attrs(io_num.n_output);
    for (uint32_t i = 0; i < io_num.n_output; i++) {
        output_attrs[i].index = i;
        ret = rknn_query(ctx, RKNN_QUERY_OUTPUT_ATTR, &(output_attrs[i]), sizeof(rknn_tensor_attr));
        if (ret != RKNN_SUCC) {
            fprintf(stderr, "[%s] rknn_query output attr 失败!\n", model_tag.c_str());
            rknn_destroy(ctx);
            return -1;
        }
    }

    if (app_ctx->rknn_ctx != 0) {
        rknn_destroy(app_ctx->rknn_ctx);
        app_ctx->rknn_ctx = 0;
    }
    app_ctx->rknn_ctx = ctx;
    app_ctx->is_quant = (output_attrs[0].qnt_type != RKNN_TENSOR_QNT_NONE ||
                         output_attrs[0].type == RKNN_TENSOR_INT8 ||
                         output_attrs[0].type == RKNN_TENSOR_UINT8);

    if (app_ctx->input_attrs) free(app_ctx->input_attrs);
    if (app_ctx->output_attrs) free(app_ctx->output_attrs);

    app_ctx->io_num = io_num;
    app_ctx->input_attrs = static_cast<rknn_tensor_attr*>(malloc(io_num.n_input * sizeof(rknn_tensor_attr)));
    app_ctx->output_attrs = static_cast<rknn_tensor_attr*>(malloc(io_num.n_output * sizeof(rknn_tensor_attr)));
    if (!app_ctx->input_attrs || !app_ctx->output_attrs) {
        if (app_ctx->input_attrs) free(app_ctx->input_attrs);
        if (app_ctx->output_attrs) free(app_ctx->output_attrs);
        rknn_destroy(ctx);
        app_ctx->rknn_ctx = 0;
        return -1;
    }
    memcpy(app_ctx->input_attrs, input_attrs.data(), io_num.n_input * sizeof(rknn_tensor_attr));
    memcpy(app_ctx->output_attrs, output_attrs.data(), io_num.n_output * sizeof(rknn_tensor_attr));

    if (input_attrs[0].n_dims == 4) {
        if (input_attrs[0].fmt == RKNN_TENSOR_NCHW || (input_attrs[0].dims[1] == 3 && input_attrs[0].dims[3] != 3)) {
            app_ctx->model_channel = input_attrs[0].dims[1];
            app_ctx->model_height = input_attrs[0].dims[2];
            app_ctx->model_width = input_attrs[0].dims[3];
        } else {
            app_ctx->model_height = input_attrs[0].dims[1];
            app_ctx->model_width = input_attrs[0].dims[2];
            app_ctx->model_channel = input_attrs[0].dims[3];
        }
    } else if (input_attrs[0].n_dims == 3) {
        if (input_attrs[0].dims[0] == 3) {
            app_ctx->model_channel = input_attrs[0].dims[0];
            app_ctx->model_height = input_attrs[0].dims[1];
            app_ctx->model_width = input_attrs[0].dims[2];
        } else {
            app_ctx->model_width = input_attrs[0].dims[0];
            app_ctx->model_height = input_attrs[0].dims[1];
            app_ctx->model_channel = input_attrs[0].dims[2];
        }
    } else {
        app_ctx->model_channel = 3;
        app_ctx->model_height = 0;
        app_ctx->model_width = 0;
    }

    return 0;
}
