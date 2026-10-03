#include "hardware/npu_infer.h"
#include "hardware/npu_worker_pool.h"
#include "hardware/vpu_decoder.h"
#include "ai/pipeline/detect_result.h"
#include "ai/pipeline/infer_pipeline.h"
#include "rknn_api.h"
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <cctype>
#include <fstream>
#include <unistd.h>
#include <ctime>
#include <atomic>

NpuChannelContext::NpuChannelContext(int ch, uint32_t core_mask, std::shared_ptr<InferPipeline> pipeline)
    : _ch(ch),
      _core_mask(core_mask),
      _pipeline(pipeline),
      _last_inferred_seq(UINT64_MAX),
      _last_pts_ms(0) {
}

NpuChannelContext::~NpuChannelContext() {
    release();
}

void* NpuChannelContext::input_buf() const {
    if (_pipeline) {
        return _pipeline->input_buf();
    }
    return nullptr;
}

bool NpuChannelContext::is_valid() const {
    return _pipeline && _pipeline->is_initialized();
}

bool NpuChannelContext::infer(image_buffer_t& img, DetectResult& result) {
    if (!_pipeline || !_pipeline->is_initialized()) {
        return false;
    }
    return _pipeline->process(img, result);
}

bool NpuChannelContext::infer_frame(const std::shared_ptr<VpuDecoder::FrameBuffer>& frame, DetectResult& result) {
    if (!_pipeline || !_pipeline->is_initialized()) {
        return false;
    }
    return _pipeline->process(frame, result);
}

void NpuChannelContext::release() {
    std::lock_guard<std::recursive_mutex> lock(_mutex);
    if (_pipeline) {
        _pipeline->release();
        _pipeline.reset();
    }
    _last_json_cache.clear();
    _last_json_cache.shrink_to_fit();
    _last_inferred_seq = UINT64_MAX;
}

NpuInfer& NpuInfer::shareInstance() {
    static NpuInfer s_instance;
    return s_instance;
}

NpuInfer::NpuInfer()
    : _configured_streams(0),
      _core_num(0),
      _pipeline(nullptr) {
}

NpuInfer::~NpuInfer() {
    deinit_engine();
}

void NpuInfer::set_pipeline(std::shared_ptr<InferPipeline> pipeline) {
    std::lock_guard<std::recursive_mutex> lock(_channels_mutex);
    _pipeline = pipeline;
}

int NpuInfer::detect_npu_core_num() {
    static int s_cached_cores = []() {
        int cores = 0;
        const char* env_core = getenv("RKNN_CORE_NUM");
        if (!env_core) env_core = getenv("NPU_CORE_NUM");
        if (env_core) {
            int c = atoi(env_core);
            if (c >= 1 && c <= 3) {
                return c;
            }
        }

        const char* env_platform = getenv("TARGET_PLATFORM");
        if (env_platform) {
            std::string ep = env_platform;
            for (char &c : ep) c = (char)tolower((unsigned char)c);
            if (ep.find("3588") != std::string::npos) {
                return 3;
            } else if (ep.find("3576") != std::string::npos) {
                return 2;
            } else if (ep.find("3568") != std::string::npos || ep.find("3566") != std::string::npos || ep.find("3562") != std::string::npos) {
                return 1;
            }
        }

        const char* dt_paths[] = {
            "/proc/device-tree/compatible",
            "/sys/firmware/devicetree/base/compatible",
            "/proc/device-tree/model",
            "/sys/firmware/devicetree/base/model",
            "/sys/bus/soc/devices/soc0/soc_id",
            "/sys/bus/soc/devices/soc0/family",
            "/sys/bus/soc/devices/soc0/machine",
            "/sys/kernel/debug/rknpu/version",
            "/proc/version"
        };

        for (const char* path : dt_paths) {
            std::ifstream file(path);
            if (file.is_open()) {
                std::string content((std::istreambuf_iterator<char>(file)),
                                     std::istreambuf_iterator<char>());
                for (char &c : content) c = (char)tolower((unsigned char)c);
                if (content.find("rk3588") != std::string::npos) {
                    cores = 3;
                    break;
                } else if (content.find("rk3576") != std::string::npos) {
                    cores = 2;
                    break;
                } else if (content.find("rk3568") != std::string::npos ||
                           content.find("rk3566") != std::string::npos ||
                           content.find("rk3562") != std::string::npos) {
                    cores = 1;
                    break;
                }
            }
        }

        if (cores == 0) {
            std::ifstream cpu_file("/proc/cpuinfo");
            if (cpu_file.is_open()) {
                std::string line;
                while (std::getline(cpu_file, line)) {
                    for (char &c : line) c = (char)tolower((unsigned char)c);
                    if (line.find("3588") != std::string::npos) {
                        cores = 3;
                        break;
                    } else if (line.find("3576") != std::string::npos) {
                        cores = 2;
                        break;
                    } else if (line.find("3568") != std::string::npos || line.find("3566") != std::string::npos) {
                        cores = 1;
                        break;
                    }
                }
            }
        }

        if (cores == 0) {
            cores = 1;
        }
        return cores;
    }();

    return s_cached_cores;
}

uint32_t NpuInfer::select_core_mask(int ch) {
    int s_core_num = _core_num > 0 ? _core_num : detect_npu_core_num();

    if (s_core_num <= 1) {
        return RKNN_NPU_CORE_AUTO;
    }

    if (ch < 0) {
        if (s_core_num == 3) return RKNN_NPU_CORE_0_1_2;
        if (s_core_num == 2) return RKNN_NPU_CORE_0_1;
        return RKNN_NPU_CORE_AUTO;
    }

    int streams = _configured_streams > 0 ? _configured_streams : (int)_channels.size();
    if (streams <= 1 && _configured_streams == 1) {
        if (s_core_num == 3) return RKNN_NPU_CORE_0_1_2;
        if (s_core_num == 2) return RKNN_NPU_CORE_0_1;
        return RKNN_NPU_CORE_AUTO;
    }

    if (s_core_num == 2) {
        if (ch % 2 == 0) return RKNN_NPU_CORE_0;
        if (ch % 2 == 1) return RKNN_NPU_CORE_1;
        return RKNN_NPU_CORE_AUTO;
    }
    if (s_core_num == 3) {
        if (ch % 3 == 0) return RKNN_NPU_CORE_0;
        if (ch % 3 == 1) return RKNN_NPU_CORE_1;
        if (ch % 3 == 2) return RKNN_NPU_CORE_2;
        return RKNN_NPU_CORE_AUTO;
    }

    return RKNN_NPU_CORE_AUTO;
}

bool NpuInfer::init_engine(const std::string& model_path, const std::string& label_path) {
    std::lock_guard<std::recursive_mutex> lock(_channels_mutex);
    if (_core_num <= 0) {
        _core_num = detect_npu_core_num();
    }

    if (!_pipeline) {
        _pipeline = std::make_shared<InferPipeline>();
    }

    if (_pipeline->is_initialized()) {
        NpuWorkerPool::instance().init(_pipeline, _core_num);
        return true;
    }

    _model_path = model_path;
    _label_path = label_path;

    bool ok = _pipeline->init(_model_path, _label_path);
    if (!ok) {
        return false;
    }

    NpuWorkerPool::instance().init(_pipeline, _core_num);
    return true;
}

void NpuInfer::deinit_engine() {
    std::lock_guard<std::recursive_mutex> lock(_channels_mutex);
    NpuWorkerPool::instance().shutdown();

    for (auto& pair : _channels) {
        if (pair.second) {
            pair.second->release();
        }
    }
    _channels.clear();

    if (_pipeline) {
        _pipeline->release();
        _pipeline.reset();
    }
}

bool NpuInfer::init(const std::string& model_path, const std::string& label_path) {
    return init_engine(model_path, label_path);
}

bool NpuInfer::create_all(int total_streams) {
    if (!init_engine(_model_path, _label_path)) {
        return false;
    }
    _configured_streams = total_streams;

    for (int ch = 0; ch < total_streams; ++ch) {
        if (!create_channel(ch)) {
            return false;
        }
    }
    return true;
}

bool NpuInfer::init_with_stream_count(int stream_count) {
    return create_all(stream_count);
}

std::shared_ptr<NpuChannelContext> NpuInfer::create_channel(int ch) {
    std::lock_guard<std::recursive_mutex> lock(_channels_mutex);
    if (!_pipeline || !_pipeline->is_initialized()) {
        if (!init_engine(_model_path, _label_path)) {
            return nullptr;
        }
    }

    auto it = _channels.find(ch);
    if (it != _channels.end()) {
        if (it->second && it->second->is_valid()) {
            std::lock_guard<std::recursive_mutex> ch_lock(it->second->mutex());
            it->second->set_last_inferred_seq(UINT64_MAX);
            it->second->set_last_pts_ms(0);
            it->second->last_json_cache().clear();
            return it->second;
        }
        _channels.erase(it);
    }

    uint32_t mask = select_core_mask(ch);
    auto ch_pipeline = _pipeline->clone(mask);
    if (!ch_pipeline) {
        return nullptr;
    }

    auto channel = std::make_shared<NpuChannelContext>(ch, mask, ch_pipeline);
    _channels[ch] = channel;
    return channel;
}

std::shared_ptr<NpuChannelContext> NpuInfer::get_channel(int ch) {
    std::lock_guard<std::recursive_mutex> lock(_channels_mutex);
    auto it = _channels.find(ch);
    if (it != _channels.end()) {
        return it->second;
    }
    return nullptr;
}

std::shared_ptr<NpuChannelContext> NpuInfer::get_or_create_channel(int ch) {
    return create_channel(ch);
}

bool NpuInfer::release_channel(int ch) {
    std::lock_guard<std::recursive_mutex> lock(_channels_mutex);
    auto it = _channels.find(ch);
    if (it != _channels.end()) {
        if (it->second) {
            it->second->release();
        }
        _channels.erase(it);
        return true;
    }
    return false;
}

bool NpuInfer::flush_channel(int ch) {
    std::shared_ptr<NpuChannelContext> channel = get_channel(ch);
    if (channel) {
        std::lock_guard<std::recursive_mutex> lock(channel->mutex());
        channel->set_last_inferred_seq(UINT64_MAX);
        channel->set_last_pts_ms(0);
        channel->last_json_cache().clear();
        return true;
    }
    return false;
}

bool NpuInfer::infer(image_buffer_t& img, DetectResult& result) {
    if (!_pipeline || !_pipeline->is_initialized()) {
        if (!init_engine(_model_path, _label_path)) {
            return false;
        }
    }
    return _pipeline->process(img, result);
}

int NpuInfer::detect_frame(VpuDecoder* decoder, int ch, char* out_buf, int out_buf_size, unsigned long long* out_frame_idx, long long* out_pts_ms) {
    if (!out_buf || out_buf_size <= 0) return -1;

    std::shared_ptr<NpuChannelContext> channel = get_channel(ch);
    if (!channel) {
        channel = create_channel(ch);
    }
    if (!channel || !_pipeline || !_pipeline->is_initialized()) {
        if (out_frame_idx) *out_frame_idx = 0;
        if (out_pts_ms) *out_pts_ms = 0;
        snprintf(out_buf, out_buf_size, "{\"frame_width\":0,\"frame_height\":0,\"detections\":[]}");
        return -1;
    }

    std::lock_guard<std::recursive_mutex> lock(channel->mutex());

    void* in_buf = channel->input_buf();
    if (!in_buf || _pipeline->input_width() <= 0 || _pipeline->input_height() <= 0) {
        if (out_frame_idx) *out_frame_idx = 0;
        if (out_pts_ms) *out_pts_ms = 0;
        snprintf(out_buf, out_buf_size, "{\"frame_width\":0,\"frame_height\":0,\"detections\":[]}");
        return -1;
    }

    if (!decoder) {
        if (out_frame_idx) *out_frame_idx = 0;
        if (out_pts_ms) *out_pts_ms = 0;
        snprintf(out_buf, out_buf_size, "{\"frame_width\":0,\"frame_height\":0,\"detections\":[]}");
        return (int)strlen(out_buf);
    }

    uint64_t peek_idx = decoder->get_latest_frame_idx();
    if (peek_idx == UINT64_MAX || peek_idx == channel->last_inferred_seq()) {
        if (out_frame_idx) *out_frame_idx = (peek_idx == UINT64_MAX ? 0 : peek_idx);
        if (out_pts_ms) *out_pts_ms = channel->last_pts_ms();
        out_buf[0] = '\0';
        return 0;
    }

    std::shared_ptr<VpuDecoder::FrameBuffer> frame_snapshot;
    if (decoder) {
        frame_snapshot = decoder->get_latest_frame_snapshot();
    }

    uint64_t frame_idx = 0;
    int64_t pts_ms = 0;
    int orig_w = 0, orig_h = 0;

    image_buffer_t dst_img;
    memset(&dst_img, 0, sizeof(image_buffer_t));
    letterbox_t letter_box;
    memset(&letter_box, 0, sizeof(letterbox_t));

    if (frame_snapshot && !frame_snapshot->data.empty()) {
        frame_idx = frame_snapshot->frame_idx;
        pts_ms = frame_snapshot->pts_ms;
        orig_w = frame_snapshot->width;
        orig_h = frame_snapshot->height;
    } else if (decoder) {
        dst_img.width = _pipeline->input_width();
        dst_img.height = _pipeline->input_height();
        dst_img.width_stride = _pipeline->input_width();
        dst_img.height_stride = _pipeline->input_height();
        dst_img.format = IMAGE_FORMAT_RGB888;
        dst_img.virt_addr = (unsigned char*)in_buf;
        dst_img.size = (int)(_pipeline->input_width() * _pipeline->input_height() * _pipeline->input_channel());
        dst_img.fd = -1;

        if (!decoder->letterbox_to_dst(&dst_img, &letter_box, frame_idx, pts_ms, &orig_w, &orig_h)) {
            if (out_frame_idx) *out_frame_idx = (frame_idx > 0 ? frame_idx : (peek_idx != UINT64_MAX ? peek_idx : 0));
            if (out_pts_ms) *out_pts_ms = (pts_ms != 0 ? pts_ms : channel->last_pts_ms());
            out_buf[0] = '\0';
            return 0;
        }
    }

    if (frame_idx == channel->last_inferred_seq()) {
        if (out_frame_idx) *out_frame_idx = frame_idx;
        if (out_pts_ms) *out_pts_ms = pts_ms;
        out_buf[0] = '\0';
        return 0;
    }

    if (out_frame_idx) *out_frame_idx = frame_idx;
    if (out_pts_ms) *out_pts_ms = pts_ms;

    struct timespec ts_start, ts_end;
    clock_gettime(CLOCK_MONOTONIC, &ts_start);

    DetectResult det_result;
    det_result.orig_width = orig_w;
    det_result.orig_height = orig_h;
    det_result.frame_idx = frame_idx;
    det_result.pts_ms = pts_ms;

    bool infer_ok = false;
    if (frame_snapshot && !frame_snapshot->data.empty()) {
        infer_ok = channel->infer_frame(frame_snapshot, det_result);
    } else {
        infer_ok = channel->infer(dst_img, det_result);
    }

    if (!infer_ok) {
        snprintf(out_buf, out_buf_size, "{\"frame_width\":%d,\"frame_height\":%d,\"detections\":[]}", orig_w, orig_h);
        return (int)strlen(out_buf);
    }

    clock_gettime(CLOCK_MONOTONIC, &ts_end);
    double cost_ms = (ts_end.tv_sec - ts_start.tv_sec) * 1000.0 + (ts_end.tv_nsec - ts_start.tv_nsec) / 1000000.0;

    std::string json;
    json.reserve(2048);
    char tmp[512];

    snprintf(tmp, sizeof(tmp), "{\"frame_width\": %d, \"frame_height\": %d, \"frame_idx\": %llu, \"pts_ms\": %lld, \"detections\": [",
             orig_w, orig_h, (unsigned long long)frame_idx, (long long)pts_ms);
    json.append(tmp);

    for (size_t i = 0; i < det_result.objects.size(); i++) {
        const auto& obj = det_result.objects[i];
        if (!obj.model_name.empty()) {
            snprintf(tmp, sizeof(tmp),
                "%s{\"model\": \"%s\", \"class_id\": %d, \"label\": \"%s\", \"confidence\": %.2f, \"rel_box\": [%.4f, %.4f, %.4f, %.4f], \"box\": [%d, %d, %d, %d]}",
                (i > 0 ? ", " : ""),
                obj.model_name.c_str(),
                obj.class_id, obj.label.c_str(), obj.score,
                obj.rel_box[0], obj.rel_box[1], obj.rel_box[2], obj.rel_box[3],
                obj.box[0], obj.box[1], obj.box[2], obj.box[3]
            );
        } else {
            snprintf(tmp, sizeof(tmp),
                "%s{\"class_id\": %d, \"label\": \"%s\", \"confidence\": %.2f, \"rel_box\": [%.4f, %.4f, %.4f, %.4f], \"box\": [%d, %d, %d, %d]}",
                (i > 0 ? ", " : ""),
                obj.class_id, obj.label.c_str(), obj.score,
                obj.rel_box[0], obj.rel_box[1], obj.rel_box[2], obj.rel_box[3],
                obj.box[0], obj.box[1], obj.box[2], obj.box[3]
            );
        }
        json.append(tmp);
    }
    json.append("]}");

    if ((int)json.size() >= out_buf_size) {
        snprintf(out_buf, out_buf_size, "{\"frame_width\":%d,\"frame_height\":%d,\"detections\":[]}", orig_w, orig_h);
        return (int)strlen(out_buf);
    }

    memcpy(out_buf, json.c_str(), json.size() + 1);

    channel->set_last_inferred_seq(frame_idx);
    channel->set_last_pts_ms(pts_ms);
    channel->last_json_cache() = json;

    static std::atomic<int> s_latest_cnt{0};
    int cur_cnt = ++s_latest_cnt;
    if (cur_cnt % 90 == 0) {
        printf("channel %d: latest infer #%d (cost=%.2fms, targets=%zu, f#%llu, pts=%lldms)\n",
               ch, cur_cnt, cost_ms, det_result.objects.size(), (unsigned long long)frame_idx, (long long)pts_ms);
        fflush(stdout);
    }

    return (int)json.size();
}

const char* NpuInfer::get_label_name(int cls_id) {
    if (_pipeline) {
        return _pipeline->get_label_name(cls_id);
    }
    return "object";
}

void NpuInfer::release() {
    deinit_engine();
}
