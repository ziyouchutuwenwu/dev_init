#include "hardware/npu_channel_context.h"
#include "hardware/vpu_decoder.h"
#include "ai/infer_manager/detect_result.h"

NpuChannelContext::NpuChannelContext(int ch, uint32_t core_mask, std::shared_ptr<InferManager> manager)
    : _ch(ch),
      _core_mask(core_mask),
      _manager(manager),
      _last_inferred_seq(UINT64_MAX),
      _last_pts_ms(0) {
}

NpuChannelContext::~NpuChannelContext() {
    release();
}

void* NpuChannelContext::input_buf() const {
    if (_manager) {
        auto m = _manager->get_group_for_channel(_ch);
        if (m) {
            return m->input_buf();
        }
        return _manager->input_buf();
    }
    return nullptr;
}

bool NpuChannelContext::is_valid() const {
    return _manager && _manager->is_initialized();
}

bool NpuChannelContext::infer(image_buffer_t& img, DetectResult& result) {
    if (!_manager || !_manager->is_initialized()) {
        return false;
    }
    auto m = _manager->get_group_for_channel(_ch);
    return m ? m->infer(img, result) : false;
}

bool NpuChannelContext::infer(const std::string& model_id, image_buffer_t& img, DetectResult& result) {
    if (!_manager || !_manager->is_initialized()) {
        return false;
    }
    auto m = _manager->get_group(model_id);
    return m ? m->infer(img, result) : false;
}

bool NpuChannelContext::infer_frame(const std::shared_ptr<VpuDecoder::FrameBuffer>& frame, DetectResult& result) {
    if (!_manager || !_manager->is_initialized()) {
        return false;
    }
    auto m = _manager->get_group_for_channel(_ch);
    return m ? m->infer_frame(frame, result) : false;
}

void NpuChannelContext::release() {
    std::lock_guard<std::recursive_mutex> lock(_mutex);
    if (_manager) {
        _manager->release();
        _manager.reset();
    }
    _last_json_cache.clear();
    _last_json_cache.shrink_to_fit();
    _last_inferred_seq = UINT64_MAX;
}
