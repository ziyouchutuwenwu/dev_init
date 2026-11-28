#pragma once

#include "ai/infer_manager/model_infer.h"
#include "ai/infer_manager/infer_manager.h"
#include <string>
#include <mutex>
#include <memory>
#include <cstdint>

class VpuDecoder;

class NpuChannelContext {
public:
    NpuChannelContext(int ch, uint32_t core_mask, std::shared_ptr<InferManager> manager);
    ~NpuChannelContext();

    bool infer(image_buffer_t& img, DetectResult& result);
    bool infer(const std::string& model_id, image_buffer_t& img, DetectResult& result);
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
