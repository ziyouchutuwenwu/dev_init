#ifndef LPRNET_INFER_H
#define LPRNET_INFER_H

#include "ai/infer_manager/model_infer.h"
#include "ai/infer_manager/detect_result.h"
#include <string>
#include <vector>
#include <memory>
#include <mutex>

class LprNetInfer : public IModelInfer, public std::enable_shared_from_this<LprNetInfer> {
public:
    explicit LprNetInfer(const std::string& name = "lprnet", const std::string& model_path = "model/lprnet.enc");
    ~LprNetInfer() override;

    const std::string& name() const override { return _name; }

    bool init(const std::string& model_path = "", const std::string& label_path = "") override;
    void release() override;
    bool is_initialized() const override { return _is_initialized; }

    int model_width() const override;
    int model_height() const override;
    int model_channel() const override;

    const char* get_label_name(int cls_id) override;
    const std::vector<std::string>& get_labels() const override;

    void* input_buf() override { return _input_buf; }

    bool infer(image_buffer_t& img, DetectResult& result) override;
    std::string recognize_plate(image_buffer_t& plate_img);

    std::shared_ptr<IModelInfer> clone(uint32_t core_mask = 0) override;

private:
    std::string find_model_path(const std::string& user_path);
    void load_default_labels();
    bool allocate_buffers();
    void free_buffers();

    std::recursive_mutex _mutex;
    std::string _name;
    std::string _model_path;
    std::shared_ptr<std::vector<std::string>> _labels;

    rknn_app_context_t _app_ctx;
    bool _is_initialized;
    bool _is_shared_ctx;
    uint32_t _core_mask;

    void* _input_buf;
    size_t _input_buf_size;
    std::vector<rknn_output> _prealloc_outputs;
    std::vector<std::vector<uint8_t>> _output_buffers;

    std::shared_ptr<std::mutex> _ctx_mutex;
    std::shared_ptr<LprNetInfer> _master_model;
};

#endif // LPRNET_INFER_H
