#pragma once

#include "hardware/npu_channel_context.h"
#include "ai/infer_manager/model_infer.h"
#include "ai/infer_manager/infer_manager.h"
#include <string>
#include <map>
#include <mutex>
#include <memory>
#include <cstdint>

class VpuDecoder;

class NpuInfer {
public:
    static NpuInfer& shareInstance();

    NpuInfer();
    ~NpuInfer();

    void set_model_manager(std::shared_ptr<InferManager> manager);
    std::shared_ptr<InferManager> get_model_manager() const { return _manager; }
    void set_infer_manager(std::shared_ptr<InferManager> manager) { set_model_manager(manager); }
    std::shared_ptr<InferManager> get_infer_manager() const { return _manager; }

    void set_pipeline(std::shared_ptr<InferManager> pipeline) { set_model_manager(pipeline); }
    std::shared_ptr<InferManager> get_pipeline() const { return _manager; }

    bool init_engine(const std::string& model_path = "", const std::string& label_path = "");
    void deinit_engine();
    bool is_ready() const { return _manager && _manager->is_initialized(); }
    bool init(const std::string& model_path = "", const std::string& label_path = "");
    bool init_with_stream_count(int stream_count);
    bool create_all(int total_streams);
    bool bind_channel(int ch, const std::string& chain_id);
    std::shared_ptr<NpuChannelContext> create_channel(int ch);
    std::shared_ptr<NpuChannelContext> get_channel(int ch);
    std::shared_ptr<NpuChannelContext> get_or_create_channel(int ch);

    bool infer(image_buffer_t& img, DetectResult& result);
    bool infer(const std::string& model_id, image_buffer_t& img, DetectResult& result);
    int detect_frame(VpuDecoder* decoder, int ch, char* out_buf, int out_buf_size, unsigned long long* out_frame_idx, long long* out_pts_ms);
    const char* get_label_name(int cls_id);
    void release();
    bool release_channel(int ch);
    bool flush_channel(int ch);
    static int detect_npu_core_num();
    int core_num() const { return _core_num > 0 ? _core_num : 1; }

private:
    uint32_t select_core_mask(int ch);

    std::recursive_mutex _channels_mutex;
    std::string _model_path;
    std::string _label_path;
    int _configured_streams;
    int _core_num;

    std::shared_ptr<InferManager> _manager;
    std::map<int, std::shared_ptr<NpuChannelContext>> _channels;
};
