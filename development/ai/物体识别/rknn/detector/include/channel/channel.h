#ifndef CHANNEL_H
#define CHANNEL_H

#include <memory>
#include <string>
#include <mutex>
#include <condition_variable>
#include <atomic>
#include <cstdint>

class VpuDecoder;
struct DetectResult;

class Channel {
public:
    explicit Channel(int ch, int codec_type = 0);
    ~Channel();

    int id() const { return _ch; }
    int bin_to_img_stream(const unsigned char* packet_data, int packet_size, unsigned long long frame_idx, long long pts_ms);
    int detect_img_bin(char* out_buf, int out_buf_size, unsigned long long* out_frame_idx, long long* out_pts_ms);
    int flush();

    bool is_valid() const;

    void on_infer_finished(uint64_t frame_idx, int64_t pts_ms, int orig_w, int orig_h, const DetectResult& result);

private:
    void try_dispatch_inference();

    int _ch;
    std::shared_ptr<VpuDecoder> _decoder;

    std::atomic<bool> _is_inferring{false};
    std::atomic<uint64_t> _last_dispatched_idx{UINT64_MAX};

    std::mutex _result_mutex;
    std::condition_variable _result_cv;
    std::string _latest_json;
    uint64_t _latest_frame_idx{0};
    int64_t _latest_pts_ms{0};
    uint64_t _last_reported_frame_idx{UINT64_MAX};
    bool _has_new_result{false};
};

#endif