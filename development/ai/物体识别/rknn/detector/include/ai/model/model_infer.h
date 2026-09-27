#ifndef MODEL_INFER_H
#define MODEL_INFER_H

#include "image_utils.h"
#include "rknn_api.h"
#include <string>
#include <memory>
#include <vector>
#include <cstdint>

struct DetectResult;

typedef struct {
    rknn_context rknn_ctx;
    rknn_input_output_num io_num;
    rknn_tensor_attr* input_attrs;
    rknn_tensor_attr* output_attrs;
    int model_channel;
    int model_width;
    int model_height;
    bool is_quant;
} rknn_app_context_t;

class IModelInfer {
public:
    virtual ~IModelInfer() = default;

    virtual bool init(const std::string& model_path = "", const std::string& label_path = "") = 0;
    virtual void release() = 0;
    virtual bool is_initialized() const = 0;

    virtual int model_width() const = 0;
    virtual int model_height() const = 0;
    virtual int model_channel() const = 0;
    virtual const char* get_label_name(int cls_id) = 0;
    virtual const std::vector<std::string>& get_labels() const = 0;

    virtual void* input_buf() = 0;
    virtual bool infer(image_buffer_t& img, DetectResult& result) = 0;

    virtual std::shared_ptr<IModelInfer> clone(uint32_t core_mask = 0) = 0;
};

#endif
