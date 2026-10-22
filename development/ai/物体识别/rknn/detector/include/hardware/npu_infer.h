#pragma once

#include "ai/infer_manager/model_infer.h"
#include "ai/infer_manager/infer_manager.h"
#include <string>
#include <map>
#include <mutex>
#include <memory>
#include <cstdint>

class VpuDecoder;

class NpuChannelContext {
public:
    NpuChannelContext(int ch, uint32_t core_mask, std::shared_ptr<InferManager> manager);
    ~NpuChannelContext();

    bool infer(image_buffer_t& img, DetectResult& result);
    bool infer_frame(const std::shared_ptr<VpuDecoder::FrameBuffer>& frame, DetectResult& result);
    void release();

    void* input_buf() const;
    bool is_valid() const;

    std::shared_ptr<InferManager> model_manager() const { return _manager; }
    std::shared_ptr<InferManager> infer_manager() const { return _manager; }
    std::shared_ptr<InferManager> pipeline() const { return _manager; }
    int channel_id() const { return _ch; }
    uint32_t core_mask() const { return _core_mask; }
    std::recursive_mutex& mutex() { return _mutex; }
    uint64_t last_inferred_seq() const { return _last_inferred_seq; }
    void set_last_inferred_seq(uint64_t seq) { _last_inferred_seq = seq; }
    int64_t last_pts_ms() const { return _last_pts_ms; }
    void set_last_pts_ms(int64_t pts) { _last_pts_ms = pts; }
    std::string& last_json_cache() { return _last_json_cache; }

private:
    int _ch;
    uint32_t _core_mask;
    std::shared_ptr<InferManager> _manager;
    std::recursive_mutex _mutex;

    uint64_t _last_inferred_seq;
    int64_t _last_pts_ms;
    std::string _last_json_cache;
};

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
    std::shared_ptr<NpuChannelContext> create_channel(int ch);
    std::shared_ptr<NpuChannelContext> get_channel(int ch);
    std::shared_ptr<NpuChannelContext> get_or_create_channel(int ch);

    bool infer(image_buffer_t& img, DetectResult& result);
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
