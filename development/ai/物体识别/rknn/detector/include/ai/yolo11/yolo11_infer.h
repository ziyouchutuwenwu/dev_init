#ifndef YOLO11_INFER_H
#define YOLO11_INFER_H

#include "ai/model/model_infer.h"
#include "ai/pipeline/detect_result.h"
#include "ai/yolo11/postprocess.h"
#include "rknn_api.h"
#include <string>
#include <vector>
#include <memory>
#include <mutex>

class Yolo11Infer : public IModelInfer, public std::enable_shared_from_this<Yolo11Infer> {
public:
    explicit Yolo11Infer(const std::string& model_name,
                         const std::string& model_path,
                         const std::string& label_path = "",
                         float conf_thresh = -1.0f,
                         float nms_thresh = -1.0f);
    virtual ~Yolo11Infer();

    const std::string& name() const override { return _model_name; }

    bool init(const std::string& model_path = "", const std::string& label_path = "") override;
    void release() override;
    bool is_initialized() const override { return _is_initialized; }

    int model_width() const override { return _app_ctx.model_width; }
    int model_height() const override { return _app_ctx.model_height; }
    int model_channel() const override { return _app_ctx.model_channel; }
    const char* get_label_name(int cls_id) override;
    const std::vector<std::string>& get_labels() const override;

    void* input_buf() override { return _input_buf; }
    bool infer(image_buffer_t& img, DetectResult& result) override;
    bool infer_frame(const std::shared_ptr<VpuDecoder::FrameBuffer>& frame, DetectResult& result) override;

    std::shared_ptr<IModelInfer> clone(uint32_t core_mask = 0) override;

private:
    bool do_infer(const letterbox_t& letter_box, DetectResult& result, int orig_w, int orig_h);
    std::string find_model_path(const std::string& user_path);
    std::string find_labels_path(const std::string& user_path);
    void load_labels(const std::string& path);
    void load_default_labels();
    bool allocate_buffers();
    void free_buffers();

    std::recursive_mutex _mutex;
    std::string _model_name;
    std::string _model_path;
    std::string _label_path;
    float _conf_thresh;
    float _nms_thresh;
    std::shared_ptr<std::vector<std::string>> _labels;

    rknn_app_context_t _app_ctx;
    bool _is_initialized;
    bool _is_shared_ctx;
    bool _postprocess_inited;
    uint32_t _core_mask;

    void* _input_buf;
    size_t _input_buf_size;
    std::vector<rknn_output> _prealloc_outputs;
    std::vector<std::vector<uint8_t>> _output_buffers;
    bool _has_prealloc_outputs;

    std::shared_ptr<Yolo11Infer> _master_model;
    std::shared_ptr<std::mutex> _ctx_mutex;
};

#endif
