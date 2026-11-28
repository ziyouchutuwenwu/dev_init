#ifndef MODEL_INFER_H
#define MODEL_INFER_H

#include "image_utils.h"
#include "rknn_api.h"
#include "ai/infer_manager/rknn_app_context.h"
#include "hardware/vpu_decoder.h"
#include <string>
#include <memory>
#include <vector>
#include <cstdint>

struct DetectResult;

class IModelInfer {
public:
    virtual ~IModelInfer() = default;

    virtual const std::string& model_id() const = 0;
    const std::string& name() const { return model_id(); }

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
    virtual bool infer_frame(const std::shared_ptr<VpuDecoder::FrameBuffer>& frame, DetectResult& result) {
        (void)frame;
        (void)result;
        return false;
    }

    virtual std::shared_ptr<IModelInfer> clone(uint32_t core_mask = 0) = 0;
};

#endif
