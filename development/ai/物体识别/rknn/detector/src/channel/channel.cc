#include "channel/channel.h"
#include "channel/channel_manager.h"
#include "engine/engine.h"
#include "hardware/vpu_decoder.h"
#include "hardware/channel_decoder.h"
#include "hardware/npu_worker_pool.h"
#include "ai/pipeline/detect_result.h"
#include <cstdio>
#include <cstring>
#include <chrono>

Channel::Channel(int ch, int codec_type) : _ch(ch) {
    _decoder = ChannelDecoder::shareInstance().create_decoder(ch, codec_type);
}

Channel::~Channel() {
    if (_decoder) {
        ChannelDecoder::shareInstance().release_decoder(_ch);
        _decoder.reset();
    }
}

bool Channel::is_valid() const {
    return _decoder != nullptr && !_decoder->is_released();
}

int Channel::bin_to_img_stream(const unsigned char* packet_data, int packet_size, unsigned long long frame_idx, long long pts_ms) {
    if (!_decoder || !packet_data || packet_size <= 0) {
        return -1;
    }
    bool ok = _decoder->feed_h264_packet(packet_data, static_cast<size_t>(packet_size), static_cast<uint64_t>(frame_idx), static_cast<int64_t>(pts_ms));
    if (ok) {
        try_dispatch_inference();
    }
    return ok ? 0 : -1;
}

void Channel::try_dispatch_inference() {
    if (!Engine::instance().is_infer_ready()) {
        return;
    }
    if (!_decoder || _is_inferring.load()) {
        return;
    }
    auto cur_frame = _decoder->get_latest_frame_snapshot();
    if (!cur_frame || cur_frame->data.empty() || cur_frame->frame_idx == UINT64_MAX) {
        return;
    }
    if (cur_frame->frame_idx == _last_dispatched_idx.load()) {
        return;
    }
    if (_is_inferring.exchange(true)) {
        return;
    }

    _last_dispatched_idx.store(cur_frame->frame_idx);

    int ch_id = _ch;
    InferTask task;
    task.channel_id = ch_id;
    task.frame = cur_frame;
    task.callback = [ch_id](int ch, uint64_t f_idx, int64_t pts, int orig_w, int orig_h, const DetectResult& res) {
        auto channel = ChannelManager::instance().get(ch);
        if (channel) {
            channel->on_infer_finished(f_idx, pts, orig_w, orig_h, res);
        }
    };

    if (!NpuWorkerPool::instance().push_task(std::move(task))) {
        _is_inferring.store(false);
    }
}

void Channel::on_infer_finished(uint64_t frame_idx, int64_t pts_ms, int orig_w, int orig_h, const DetectResult& result) {
    std::string json;
    json.reserve(2048);
    char tmp[512];

    snprintf(tmp, sizeof(tmp), "{\"frame_width\": %d, \"frame_height\": %d, \"frame_idx\": %llu, \"pts_ms\": %lld, \"detections\": [",
             orig_w, orig_h, (unsigned long long)frame_idx, (long long)pts_ms);
    json.append(tmp);

    for (size_t i = 0; i < result.objects.size(); i++) {
        const auto& obj = result.objects[i];
        snprintf(tmp, sizeof(tmp),
            "%s{\"class_id\": %d, \"label\": \"%s\", \"confidence\": %.2f, \"rel_box\": [%.4f, %.4f, %.4f, %.4f], \"box\": [%d, %d, %d, %d]}",
            (i > 0 ? ", " : ""),
            obj.class_id, obj.label.c_str(), obj.score,
            obj.rel_box[0], obj.rel_box[1], obj.rel_box[2], obj.rel_box[3],
            obj.box[0], obj.box[1], obj.box[2], obj.box[3]
        );
        json.append(tmp);
    }
    json.append("]}");

    {
        std::lock_guard<std::mutex> lock(_result_mutex);
        _latest_json = std::move(json);
        _latest_frame_idx = frame_idx;
        _latest_pts_ms = pts_ms;
        _has_new_result = true;
    }

    _is_inferring.store(false);
    _result_cv.notify_one();

    try_dispatch_inference();
}

int Channel::detect_img_bin(char* out_buf, int out_buf_size, unsigned long long* out_frame_idx, long long* out_pts_ms) {
    if (!out_buf || out_buf_size <= 0) {
        return -1;
    }

    if (!Engine::instance().is_infer_ready()) {
        out_buf[0] = '\0';
        if (out_frame_idx) *out_frame_idx = (_latest_frame_idx > 0 ? _latest_frame_idx : 0);
        if (out_pts_ms) *out_pts_ms = _latest_pts_ms;
        return 0;
    }

    try_dispatch_inference();

    std::unique_lock<std::mutex> lock(_result_mutex);
    if (!_has_new_result && _is_inferring.load()) {
        _result_cv.wait_for(lock, std::chrono::milliseconds(25), [this] {
            return _has_new_result || !_is_inferring.load();
        });
    }

    if (_has_new_result && !_latest_json.empty() && _latest_frame_idx != _last_reported_frame_idx) {
        if ((int)_latest_json.size() >= out_buf_size) {
            snprintf(out_buf, out_buf_size, "{\"frame_width\":0,\"frame_height\":0,\"detections\":[]}");
            return (int)strlen(out_buf);
        }
        memcpy(out_buf, _latest_json.c_str(), _latest_json.size() + 1);
        if (out_frame_idx) *out_frame_idx = _latest_frame_idx;
        if (out_pts_ms) *out_pts_ms = _latest_pts_ms;
        _last_reported_frame_idx = _latest_frame_idx;
        _has_new_result = false;
        return (int)_latest_json.size();
    }

    out_buf[0] = '\0';
    if (out_frame_idx) *out_frame_idx = (_latest_frame_idx > 0 ? _latest_frame_idx : 0);
    if (out_pts_ms) *out_pts_ms = _latest_pts_ms;
    return 0;
}

int Channel::flush() {
    bool d_ok = ChannelDecoder::shareInstance().flush_decoder(_ch);
    {
        std::lock_guard<std::mutex> lock(_result_mutex);
        _latest_json.clear();
        _has_new_result = false;
        _latest_frame_idx = 0;
        _latest_pts_ms = 0;
        _last_reported_frame_idx = UINT64_MAX;
    }
    _last_dispatched_idx.store(UINT64_MAX);
    _is_inferring.store(false);
    return d_ok ? 0 : -1;
}
