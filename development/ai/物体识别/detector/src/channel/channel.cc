#include "channel/channel.h"
#include "channel/channel_manager.h"
#include "engine/engine.h"
#include "hardware/vpu_decoder.h"
#include "hardware/channel_decoder.h"
#include "hardware/npu_worker_pool.h"
#include "ai/infer_manager/detect_result.h"
#include <cstdio>
#include <cstring>
#include <chrono>

static std::atomic<uint64_t> s_global_channel_epoch{1000};

Channel::Channel(int ch, int codec_type, const std::string& model_id)
    : _ch(ch), _model_id(model_id), _flush_epoch(s_global_channel_epoch.fetch_add(1000)) {
    _decoder = ChannelDecoder::shareInstance().create_decoder(ch, codec_type);
}

Channel::~Channel() {
    if (_decoder) {
        ChannelDecoder::shareInstance().release_decoder(_ch, _decoder);
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
    if (!cur_frame || (cur_frame->dma_fd < 0 && cur_frame->data.empty()) || cur_frame->frame_idx == UINT64_MAX) {
        return;
    }
    uint64_t last_idx = _last_dispatched_idx.load();
    if (last_idx != UINT64_MAX && cur_frame->frame_idx < last_idx + 5) {
        return;
    }

    if (_is_inferring.exchange(true)) {
        return;
    }

    int ch_id = _ch;
    uint64_t current_epoch = _flush_epoch.load();
    std::string task_model;
    {
        std::lock_guard<std::mutex> lock(_model_mutex);
        task_model = _model_id;
    }

    std::weak_ptr<Channel> weak_self = std::weak_ptr<Channel>(shared_from_this());

    InferTask task;
    task.channel_id = ch_id;
    task.model_id = task_model;
    task.frame = cur_frame;
    task.callback = [weak_self, current_epoch, task_model](int ch, uint64_t f_idx, int64_t pts, int orig_w, int orig_h, const DetectResult& res) {
        auto self = weak_self.lock();
        if (self) {
            self->on_infer_finished(current_epoch, task_model, f_idx, pts, orig_w, orig_h, res);
        }
    };

    if (NpuWorkerPool::instance().push_task(std::move(task))) {
        _last_infer_pts_ms.store(cur_frame->pts_ms);
        _last_dispatched_idx.store(cur_frame->frame_idx);
    } else {
        _is_inferring.store(false);
    }
}

static std::string escape_json_string(const std::string& input) {
    std::string out;
    out.reserve(input.size() + 8);
    for (char c : input) {
        switch (c) {
            case '"': out += "\\\""; break;
            case '\\': out += "\\\\"; break;
            case '\b': out += "\\b"; break;
            case '\f': out += "\\f"; break;
            case '\n': out += "\\n"; break;
            case '\r': out += "\\r"; break;
            case '\t': out += "\\t"; break;
            default:
                if (static_cast<unsigned char>(c) < 0x20) {
                    char buf[8];
                    snprintf(buf, sizeof(buf), "\\u%04x", (unsigned char)c);
                    out += buf;
                } else {
                    out += c;
                }
                break;
        }
    }
    return out;
}

void Channel::on_infer_finished(uint64_t task_epoch, const std::string& task_model, uint64_t frame_idx, int64_t pts_ms, int orig_w, int orig_h, const DetectResult& result) {
    if (task_epoch != _flush_epoch.load()) {
        _is_inferring.store(false);
        try_dispatch_inference();
        return;
    }

    if (orig_w <= 0 || orig_h <= 0) {
        _is_inferring.store(false);
        _result_cv.notify_one();
        try_dispatch_inference();
        return;
    }

    std::string json;
    json.reserve(4096);

    std::string active_model = !task_model.empty() ? task_model : model_id();
    std::string safe_active_model = escape_json_string(active_model);
    char head_buf[256];
    if (!safe_active_model.empty()) {
        snprintf(head_buf, sizeof(head_buf), "{\"model_id\": \"%s\", \"frame_width\": %d, \"frame_height\": %d, \"frame_idx\": %llu, \"pts_ms\": %lld, \"detections\": [",
                 safe_active_model.c_str(), orig_w, orig_h, (unsigned long long)frame_idx, (long long)pts_ms);
    } else {
        snprintf(head_buf, sizeof(head_buf), "{\"frame_width\": %d, \"frame_height\": %d, \"frame_idx\": %llu, \"pts_ms\": %lld, \"detections\": [",
                 orig_w, orig_h, (unsigned long long)frame_idx, (long long)pts_ms);
    }
    json.append(head_buf);

    for (size_t i = 0; i < result.objects.size(); i++) {
        const auto& obj = result.objects[i];
        if (i > 0) {
            json.append(", ");
        }
        json.append("{");
        if (!obj.model_id.empty()) {
            std::string safe_model_id = escape_json_string(obj.model_id);
            json.append("\"model_id\": \"");
            json.append(safe_model_id);
            json.append("\", ");
        }

        std::string safe_label = escape_json_string(obj.label);
        json.append("\"class_id\": ");
        json.append(std::to_string(obj.class_id));
        json.append(", \"label\": \"");
        json.append(safe_label);
        json.append("\"");

        if (!obj.text.empty()) {
            std::string safe_text = escape_json_string(obj.text);
            json.append(", \"text\": \"");
            json.append(safe_text);
            json.append("\"");
        }

        char num_buf[256];
        snprintf(num_buf, sizeof(num_buf),
                 ", \"confidence\": %.2f, \"rel_box\": [%.4f, %.4f, %.4f, %.4f], \"box\": [%d, %d, %d, %d]",
                 obj.score,
                 obj.rel_box[0], obj.rel_box[1], obj.rel_box[2], obj.rel_box[3],
                 obj.box[0], obj.box[1], obj.box[2], obj.box[3]);
        json.append(num_buf);

        if (!obj.keypoints.empty()) {
            json.append(", \"keypoints\": [");
            for (size_t k = 0; k < obj.keypoints.size(); ++k) {
                if (k > 0) json.append(", ");
                char kp_buf[32];
                snprintf(kp_buf, sizeof(kp_buf), "%.2f", obj.keypoints[k]);
                json.append(kp_buf);
            }
            json.append("]");
        }
        json.append("}");
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
            if (out_frame_idx) *out_frame_idx = _latest_frame_idx;
            if (out_pts_ms) *out_pts_ms = _latest_pts_ms;
            _last_reported_frame_idx = _latest_frame_idx;
            _has_new_result = false;
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
    _flush_epoch.fetch_add(1);
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
    _last_infer_pts_ms = 0;
    _is_inferring.store(false);
    return d_ok ? 0 : -1;
}
