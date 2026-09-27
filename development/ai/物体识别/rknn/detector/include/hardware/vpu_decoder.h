#pragma once

#include "rk_mpi.h"
#include "rk_mpi_cmd.h"
#include "mpp_buffer.h"
#include "mpp_frame.h"
#include "mpp_packet.h"
#include "mpp_err.h"
#include "image_utils.h"
#include <vector>
#include <deque>
#include <utility>
#include <mutex>
#include <cstdint>
#include <cstddef>
#include <memory>

class VpuDecoder {
public:
    explicit VpuDecoder(int codec_type = 0);
    ~VpuDecoder();

    void set_codec_type(int codec) { _codec_type = codec; }
    int codec_type() const { return _codec_type; }

    bool decode_raw_buffer(const unsigned char* data, int width, int height, int channels, image_buffer_t& frame);
    bool feed_h264_packet(const unsigned char* packet_data, size_t packet_size, uint64_t frame_idx = 0, int64_t pts_ms = 0);
    bool get_latest_frame(std::vector<unsigned char>& out_buffer, image_buffer_t& frame, uint64_t& out_frame_idx, int64_t& out_pts_ms);
    bool get_latest_frame(void* out_buffer, size_t out_buf_capacity, image_buffer_t& frame, uint64_t& out_frame_idx, int64_t& out_pts_ms);
    bool letterbox_to_dst(image_buffer_t* dst_img, letterbox_t* letter_box, uint64_t& out_frame_idx, int64_t& out_pts_ms, int* orig_w = nullptr, int* orig_h = nullptr);
    uint64_t get_latest_frame_idx();
    void flush();
    void release_mpp();
    bool is_released() const { return _is_released; }

    struct FrameBuffer {
        std::vector<unsigned char> data;
        int width = 0;
        int height = 0;
        int hor_stride = 0;
        int ver_stride = 0;
        uint64_t frame_idx = 0;
        int64_t pts_ms = 0;
    };

    std::shared_ptr<FrameBuffer> get_latest_frame_snapshot();
    static bool letterbox_frame(const std::shared_ptr<FrameBuffer>& cur_frame, image_buffer_t* dst_img, letterbox_t* letter_box, int* orig_w = nullptr, int* orig_h = nullptr);

private:
    bool init_mpp(int codec_type = -1);
    void release_mpp_internal();
    static int probe_codec(const unsigned char* data, size_t size);
    bool decode_h264_packet(const unsigned char* packet_data, size_t packet_size, image_buffer_t& frame, uint64_t frame_idx = 0, int64_t pts_ms = 0);
    void drain_frames(bool& got_new_frame);

    void* get_buf_ptr(MppBuffer buf, const char* caller);
    int get_buf_fd(MppBuffer buf, const char* caller);
    size_t get_buf_size(MppBuffer buf, const char* caller);

    void* _mpp_handle;
    MppCtx _ctx;
    MppApi* _mpi;
    MppBufferGroup _frm_grp;
    MppPacket _packet;
    bool _is_mpp_inited;
    bool _is_released;
    size_t _current_buf_size;
    int _codec_type{0};

    std::mutex _decode_mutex;
    std::vector<unsigned char> _feed_buf;
    std::mutex _frame_mutex;
    std::shared_ptr<FrameBuffer> _latest_frame;
    std::shared_ptr<FrameBuffer> _write_frame;
    std::deque<std::pair<int64_t, uint64_t>> _pts_idx_queue;
    std::vector<unsigned char> _raw_decode_buf;
    int _frame_poll_count{0};
    int _nobuf_cnt{0};
    int _dec_fail{0};
    bool _logged_first{false};
    uint64_t _fallback_seq{1000000};

    MPP_RET (*_p_mpp_create)(MppCtx *, MppApi **){nullptr};
    MPP_RET (*_p_mpp_init)(MppCtx, MppCtxType, MppCodingType){nullptr};
    MPP_RET (*_p_mpp_destroy)(MppCtx){nullptr};
    MPP_RET (*_p_mpp_packet_init)(MppPacket *, void *, size_t){nullptr};
    MPP_RET (*_p_mpp_packet_deinit)(MppPacket *){nullptr};
    void (*_p_mpp_packet_set_data)(MppPacket, void *){nullptr};
    void (*_p_mpp_packet_set_size)(MppPacket, size_t){nullptr};
    void (*_p_mpp_packet_set_pos)(MppPacket, void *){nullptr};
    void (*_p_mpp_packet_set_length)(MppPacket, size_t){nullptr};
    void (*_p_mpp_packet_set_pts)(MppPacket, RK_S64){nullptr};
    MPP_RET (*_p_mpp_frame_init)(MppFrame *){nullptr};
    MPP_RET (*_p_mpp_frame_deinit)(MppFrame *){nullptr};
    RK_S64 (*_p_mpp_frame_get_pts)(const MppFrame){nullptr};
    RK_U32 (*_p_mpp_frame_get_info_change)(MppFrame){nullptr};
    RK_U32 (*_p_mpp_frame_get_errinfo)(MppFrame){nullptr};
    RK_U32 (*_p_mpp_frame_get_discard)(MppFrame){nullptr};
    MppBuffer (*_p_mpp_frame_get_buffer)(MppFrame){nullptr};
    RK_U32 (*_p_mpp_frame_get_width)(MppFrame){nullptr};
    RK_U32 (*_p_mpp_frame_get_height)(MppFrame){nullptr};
    RK_U32 (*_p_mpp_frame_get_hor_stride)(MppFrame){nullptr};
    RK_U32 (*_p_mpp_frame_get_ver_stride)(MppFrame){nullptr};
    RK_U32 (*_p_mpp_frame_get_buf_size)(MppFrame){nullptr};
    MppFrameFormat (*_p_mpp_frame_get_fmt)(MppFrame){nullptr};
    void* (*_p_mpp_buffer_get_ptr_with_caller)(MppBuffer, const char *){nullptr};
    void* (*_p_mpp_buffer_get_ptr_legacy)(MppBuffer){nullptr};
    int (*_p_mpp_buffer_get_fd_with_caller)(MppBuffer, const char *){nullptr};
    int (*_p_mpp_buffer_get_fd_legacy)(MppBuffer){nullptr};
    size_t (*_p_mpp_buffer_get_size_with_caller)(MppBuffer, const char *){nullptr};
    size_t (*_p_mpp_buffer_get_size_legacy)(MppBuffer){nullptr};
    MPP_RET (*_p_mpp_buffer_group_get)(MppBufferGroup *, MppBufferType, MppBufferMode, const char *, const char *){nullptr};
    MPP_RET (*_p_mpp_buffer_group_limit_config)(MppBufferGroup, size_t, RK_S32){nullptr};
    MPP_RET (*_p_mpp_buffer_group_put)(MppBufferGroup){nullptr};
    MPP_RET (*_p_mpp_buffer_group_clear)(MppBufferGroup){nullptr};
};
