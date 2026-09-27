#include "security/model_decrypter.h"
#include "security/switcher.h"
#include "model_license.h"
#include "utils/path_utils.h"
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <vector>

ModelDecrypter& ModelDecrypter::instance() {
    static ModelDecrypter s_instance;
    return s_instance;
}

std::string ModelDecrypter::resolve_file_path(const std::string& path) {
    return PathUtils::resolve_path(path);
}

const char* const* ModelDecrypter::get_labels_list() {
    return ::get_labels_list();
}

std::string ModelDecrypter::find_model_path(const std::string& user_path, const std::string& default_model_name) {
    if (!user_path.empty()) {
        std::string resolved = resolve_file_path(user_path);
        if (!resolved.empty()) return resolved;
        return user_path;
    }

    if (!default_model_name.empty()) {
        std::vector<std::string> candidates;
        if (default_model_name.find('.') != std::string::npos) {
            candidates = {
                default_model_name,
                "model/" + default_model_name,
                "../model/" + default_model_name,
                "../deploy/" + default_model_name,
                "deploy/" + default_model_name
            };
        } else {
            std::string ext = (ENABLE_SECURITY ? ".enc" : ".rknn");
            candidates = {
                default_model_name + ext,
                "model/" + default_model_name + ext,
                "../model/" + default_model_name + ext,
                "../deploy/" + default_model_name + ext,
                "deploy/" + default_model_name + ext
            };
        }
        for (const auto& c : candidates) {
            std::string r = resolve_file_path(c);
            if (!r.empty()) return r;
        }
    }

    std::string fallback_list[] = {
#if ENABLE_SECURITY
        "model.enc",
        "yolo11.enc",
        "model/model.enc",
        "model/yolo11.enc",
        "../model/model.enc",
        "../model/yolo11.enc",
        "../deploy/model.enc",
        "deploy/model.enc"
#else
        "yolo11.rknn",
        "yolov8.rknn",
        "model/yolo11.rknn",
        "model/yolov8.rknn",
        "../model/yolo11.rknn",
        "../model/yolov8.rknn",
        "../deploy/yolo11.rknn",
        "deploy/yolo11.rknn"
#endif
    };

    for (const auto& p : fallback_list) {
        std::string r = resolve_file_path(p);
        if (!r.empty()) return r;
    }

    if (!default_model_name.empty()) {
        return default_model_name;
    }
#if ENABLE_SECURITY
    return "model.enc";
#else
    return "yolo11.rknn";
#endif
}

bool ModelDecrypter::load_model_memory(const std::string& model_path, ModelMemory& out_buf, const std::string& default_model_name) {
    out_buf.release();

    std::string resolved = find_model_path(model_path, default_model_name);
    if (resolved.empty() || access(resolved.c_str(), R_OK) != 0) {
        fprintf(stderr, "错误: 找不到模型文件: %s\n", resolved.c_str());
        return false;
    }

#if !ENABLE_SECURITY
    FILE* fp = fopen(resolved.c_str(), "rb");
    if (!fp) {
        fprintf(stderr, "错误: 无法打开明文模型文件: %s\n", resolved.c_str());
        return false;
    }
    fseek(fp, 0, SEEK_END);
    long sz = ftell(fp);
    fseek(fp, 0, SEEK_SET);
    if (sz <= 0) {
        fclose(fp);
        return false;
    }

    uint8_t* buf = static_cast<uint8_t*>(malloc(static_cast<size_t>(sz)));
    if (!buf) {
        fclose(fp);
        return false;
    }
    size_t rd = fread(buf, 1, static_cast<size_t>(sz), fp);
    fclose(fp);
    if (rd != static_cast<size_t>(sz)) {
        free(buf);
        return false;
    }

    out_buf.data = buf;
    out_buf.size = static_cast<size_t>(sz);
    out_buf.is_encrypted_mem = false;
    return true;
#else
    FILE* fp = fopen(resolved.c_str(), "rb");
    if (!fp) {
        fprintf(stderr, "错误: 无法打开模型文件: %s\n", resolved.c_str());
        return false;
    }

    bool is_encrypted = false;
    if (resolved.size() >= 4 && resolved.substr(resolved.size() - 4) == ".enc") {
        is_encrypted = true;
    } else {
        char magic[16] = {0};
        size_t n = fread(magic, 1, sizeof(magic), fp);
        if (n >= 16 && memcmp(magic, "model_encrypted\0", 16) == 0) {
            is_encrypted = true;
        } else if (n >= 8 && (memcmp(magic, "rkmod02\0", 8) == 0 || memcmp(magic, "rkmod01\0", 8) == 0)) {
            is_encrypted = true;
        }
    }
    fclose(fp);

    if (!is_encrypted) {
        fprintf(stderr, "=========================================================\n");
        fprintf(stderr, "错误: 安全模式已开启，禁止加载未加密的明文模型！\n");
        fprintf(stderr, "  • 检测到的模型文件: %s\n", resolved.c_str());
        fprintf(stderr, "  • 请使用 model_tool 工具加密模型后使用 .enc 文件运行\n");
        fprintf(stderr, "=========================================================\n");
        return false;
    }

    uint8_t* out_ptr = nullptr;
    size_t out_len = 0;
    int ret = decrypt_model(resolved.c_str(), &out_ptr, &out_len);
    if (ret != 0 || !out_ptr || out_len == 0) {
        if (out_ptr && out_len > 0) {
            free_model_memory(out_ptr, out_len);
        } else if (out_ptr) {
            free(out_ptr);
        }
        fprintf(stderr, "错误: 加密模型解密失败 (ret=%d)！文件: %s\n", ret, resolved.c_str());
        return false;
    }

    out_buf.data = out_ptr;
    out_buf.size = out_len;
    out_buf.is_encrypted_mem = true;
    return true;
#endif
}

std::string ModelDecrypter::get_encrypted_model_id(const std::string& model_path) {
    std::string resolved = find_model_path(model_path);
    if (resolved.empty()) return "";
    char id_buf[128] = {0};
    int ret = ::get_model_id(resolved.c_str(), id_buf, sizeof(id_buf));
    if (ret == 0) {
        return std::string(id_buf);
    }
    return "";
}

int ModelDecrypter::init_model(const std::string& model_path, rknn_app_context_t* app_ctx, const std::string& model_tag, const std::string& default_name) {
    if (!app_ctx) return -1;

    ModelMemory mem_buf;
    if (!load_model_memory(model_path, mem_buf, default_name)) {
        return -1;
    }

    rknn_context ctx = 0;
    int ret = rknn_init(&ctx, mem_buf.data, static_cast<uint32_t>(mem_buf.size), 0, NULL);

    mem_buf.release();

    if (ret < 0) {
        fprintf(stderr, "[%s] rknn_init 失败! ret=%d\n", model_tag.c_str(), ret);
        return -1;
    }

    rknn_input_output_num io_num;
    ret = rknn_query(ctx, RKNN_QUERY_IN_OUT_NUM, &io_num, sizeof(io_num));
    if (ret != RKNN_SUCC) {
        fprintf(stderr, "[%s] rknn_query RKNN_QUERY_IN_OUT_NUM 失败! ret=%d\n", model_tag.c_str(), ret);
        rknn_destroy(ctx);
        return -1;
    }

    if (io_num.n_input == 0 || io_num.n_output == 0) {
        fprintf(stderr, "[%s] rknn io_num 异常: inputs=%u, outputs=%u\n", model_tag.c_str(), io_num.n_input, io_num.n_output);
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
    if (output_attrs[0].qnt_type != RKNN_TENSOR_QNT_NONE || output_attrs[0].type == RKNN_TENSOR_INT8 || output_attrs[0].type == RKNN_TENSOR_UINT8) {
        app_ctx->is_quant = true;
    } else {
        app_ctx->is_quant = false;
    }

    if (app_ctx->input_attrs) {
        free(app_ctx->input_attrs);
        app_ctx->input_attrs = nullptr;
    }
    if (app_ctx->output_attrs) {
        free(app_ctx->output_attrs);
        app_ctx->output_attrs = nullptr;
    }

    app_ctx->io_num = io_num;
    app_ctx->input_attrs = static_cast<rknn_tensor_attr*>(malloc(io_num.n_input * sizeof(rknn_tensor_attr)));
    app_ctx->output_attrs = static_cast<rknn_tensor_attr*>(malloc(io_num.n_output * sizeof(rknn_tensor_attr)));
    if (!app_ctx->input_attrs || !app_ctx->output_attrs) {
        if (app_ctx->input_attrs) {
            free(app_ctx->input_attrs);
            app_ctx->input_attrs = nullptr;
        }
        if (app_ctx->output_attrs) {
            free(app_ctx->output_attrs);
            app_ctx->output_attrs = nullptr;
        }
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
            app_ctx->model_height = input_attrs[0].dims[0];
            app_ctx->model_width = input_attrs[0].dims[1];
            app_ctx->model_channel = input_attrs[0].dims[2];
        }
    }

    return 0;
}
