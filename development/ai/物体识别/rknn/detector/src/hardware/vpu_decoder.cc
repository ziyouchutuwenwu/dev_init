#include "hardware/vpu_decoder.h"
#include "im2d.h"
#include "RgaApi.h"
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <dlfcn.h>
#include <unistd.h>
#include <atomic>
#include <algorithm>
#include <sys/mman.h>

#define MPP_LIB_NAME    "librockchip_mpp.so"

VpuDecoder::VpuDecoder(int codec_type)
    : _mpp_handle(nullptr),
      _ctx(nullptr),
      _mpi(nullptr),
      _frm_grp(nullptr),
      _packet(nullptr),
      _is_mpp_inited(false),
      _is_released(false),
      _current_buf_size(0),
      _codec_type(codec_type),
      _p_mpp_buffer_get_ptr_with_caller(nullptr),
      _p_mpp_buffer_get_ptr_legacy(nullptr),
      _p_mpp_buffer_get_fd_with_caller(nullptr),
      _p_mpp_buffer_get_fd_legacy(nullptr),
      _p_mpp_buffer_get_size_with_caller(nullptr),
      _p_mpp_buffer_get_size_legacy(nullptr) {
    _feed_buf.reserve(1 * 1024 * 1024);
    _write_frame = std::make_shared<FrameBuffer>();
    _write_frame->data.reserve(4 * 1024 * 1024);
}

VpuDecoder::~VpuDecoder() {
    release_mpp();
}

void* VpuDecoder::get_buf_ptr(MppBuffer buf, const char* caller) {
    if (!buf) return nullptr;
    if (_p_mpp_buffer_get_ptr_with_caller) {
        return _p_mpp_buffer_get_ptr_with_caller(buf, caller);
    }
    if (_p_mpp_buffer_get_ptr_legacy) {
        return _p_mpp_buffer_get_ptr_legacy(buf);
    }
    return nullptr;
}

int VpuDecoder::get_buf_fd(MppBuffer buf, const char* caller) {
    if (!buf) return -1;
    if (_p_mpp_buffer_get_fd_with_caller) {
        return _p_mpp_buffer_get_fd_with_caller(buf, caller);
    }
    if (_p_mpp_buffer_get_fd_legacy) {
        return _p_mpp_buffer_get_fd_legacy(buf);
    }
    return -1;
}

size_t VpuDecoder::get_buf_size(MppBuffer buf, const char* caller) {
    if (!buf) return 0;
    if (_p_mpp_buffer_get_size_with_caller) {
        return _p_mpp_buffer_get_size_with_caller(buf, caller);
    }
    if (_p_mpp_buffer_get_size_legacy) {
        return _p_mpp_buffer_get_size_legacy(buf);
    }
    return 0;
}

bool VpuDecoder::init_mpp(int codec_type) {
    if (codec_type >= 0) {
        _codec_type = codec_type;
    }
    if (_is_mpp_inited) {
        return true;
    }

    static void* s_mpp_handle = nullptr;
    static std::mutex s_mpp_mutex;
    if (!s_mpp_handle) {
        std::lock_guard<std::mutex> lock(s_mpp_mutex);
        if (!s_mpp_handle) {
            s_mpp_handle = dlopen(MPP_LIB_NAME, RTLD_LAZY | RTLD_GLOBAL);
        }
    }
    _mpp_handle = s_mpp_handle;

    if (!_mpp_handle) {
        printf("mpp library not found.\n");
        return false;
    }

    _p_mpp_create = (MPP_RET (*)(MppCtx *, MppApi **))dlsym(_mpp_handle, "mpp_create");
    _p_mpp_init = (MPP_RET (*)(MppCtx, MppCtxType, MppCodingType))dlsym(_mpp_handle, "mpp_init");
    _p_mpp_destroy = (MPP_RET (*)(MppCtx))dlsym(_mpp_handle, "mpp_destroy");
    _p_mpp_packet_init = (MPP_RET (*)(MppPacket *, void *, size_t))dlsym(_mpp_handle, "mpp_packet_init");
    _p_mpp_packet_deinit = (MPP_RET (*)(MppPacket *))dlsym(_mpp_handle, "mpp_packet_deinit");
    _p_mpp_packet_set_data = (void (*)(MppPacket, void *))dlsym(_mpp_handle, "mpp_packet_set_data");
    _p_mpp_packet_set_size = (void (*)(MppPacket, size_t))dlsym(_mpp_handle, "mpp_packet_set_size");
    _p_mpp_packet_set_pos = (void (*)(MppPacket, void *))dlsym(_mpp_handle, "mpp_packet_set_pos");
    _p_mpp_packet_set_length = (void (*)(MppPacket, size_t))dlsym(_mpp_handle, "mpp_packet_set_length");
    _p_mpp_packet_set_pts = (void (*)(MppPacket, RK_S64))dlsym(_mpp_handle, "mpp_packet_set_pts");
    _p_mpp_frame_init = (MPP_RET (*)(MppFrame *))dlsym(_mpp_handle, "mpp_frame_init");
    _p_mpp_frame_deinit = (MPP_RET (*)(MppFrame *))dlsym(_mpp_handle, "mpp_frame_deinit");
    _p_mpp_frame_get_pts = (RK_S64 (*)(const MppFrame))dlsym(_mpp_handle, "mpp_frame_get_pts");
    _p_mpp_frame_get_info_change = (RK_U32 (*)(MppFrame))dlsym(_mpp_handle, "mpp_frame_get_info_change");
    _p_mpp_frame_get_errinfo = (RK_U32 (*)(MppFrame))dlsym(_mpp_handle, "mpp_frame_get_errinfo");
    _p_mpp_frame_get_discard = (RK_U32 (*)(MppFrame))dlsym(_mpp_handle, "mpp_frame_get_discard");
    _p_mpp_frame_get_buffer = (MppBuffer (*)(MppFrame))dlsym(_mpp_handle, "mpp_frame_get_buffer");
    _p_mpp_frame_get_width = (RK_U32 (*)(MppFrame))dlsym(_mpp_handle, "mpp_frame_get_width");
    _p_mpp_frame_get_height = (RK_U32 (*)(MppFrame))dlsym(_mpp_handle, "mpp_frame_get_height");
    _p_mpp_frame_get_hor_stride = (RK_U32 (*)(MppFrame))dlsym(_mpp_handle, "mpp_frame_get_hor_stride");
    _p_mpp_frame_get_ver_stride = (RK_U32 (*)(MppFrame))dlsym(_mpp_handle, "mpp_frame_get_ver_stride");
    _p_mpp_frame_get_buf_size = (RK_U32 (*)(MppFrame))dlsym(_mpp_handle, "mpp_frame_get_buf_size");
    _p_mpp_frame_get_fmt = (MppFrameFormat (*)(MppFrame))dlsym(_mpp_handle, "mpp_frame_get_fmt");

    _p_mpp_buffer_get_ptr_with_caller = (void* (*)(MppBuffer, const char *))dlsym(_mpp_handle, "mpp_buffer_get_ptr_with_caller");
    _p_mpp_buffer_get_ptr_legacy = (void* (*)(MppBuffer))dlsym(_mpp_handle, "mpp_buffer_get_ptr");

    _p_mpp_buffer_get_fd_with_caller = (int (*)(MppBuffer, const char *))dlsym(_mpp_handle, "mpp_buffer_get_fd_with_caller");
    _p_mpp_buffer_get_fd_legacy = (int (*)(MppBuffer))dlsym(_mpp_handle, "mpp_buffer_get_fd");

    _p_mpp_buffer_get_size_with_caller = (size_t (*)(MppBuffer, const char *))dlsym(_mpp_handle, "mpp_buffer_get_size_with_caller");
    _p_mpp_buffer_get_size_legacy = (size_t (*)(MppBuffer))dlsym(_mpp_handle, "mpp_buffer_get_size");

    _p_mpp_buffer_group_get = (MPP_RET (*)(MppBufferGroup *, MppBufferType, MppBufferMode, const char *, const char *))dlsym(_mpp_handle, "mpp_buffer_group_get");
    _p_mpp_buffer_group_limit_config = (MPP_RET (*)(MppBufferGroup, size_t, RK_S32))dlsym(_mpp_handle, "mpp_buffer_group_limit_config");
    _p_mpp_buffer_group_put = (MPP_RET (*)(MppBufferGroup))dlsym(_mpp_handle, "mpp_buffer_group_put");
    _p_mpp_buffer_group_clear = (MPP_RET (*)(MppBufferGroup))dlsym(_mpp_handle, "mpp_buffer_group_clear");

    if (!_p_mpp_create || !_p_mpp_init || !_p_mpp_destroy || !_p_mpp_packet_init) {
        printf("failed to resolve required mpp symbols.\n");
        _mpp_handle = nullptr;
        return false;
    }

    MPP_RET ret = _p_mpp_create(&_ctx, &_mpi);
    if (ret != MPP_OK || !_ctx || !_mpi) {
        printf("mpp_create failed (%d)\n", ret);
        return false;
    }

    RK_U32 need_split = 1;
    _mpi->control(_ctx, MPP_DEC_SET_PARSER_SPLIT_MODE, &need_split);

    RK_U32 fast_mode = 1;
    _mpi->control(_ctx, MPP_DEC_SET_PARSER_FAST_MODE, &fast_mode);

    MppCodingType coding_type = MPP_VIDEO_CodingUnused;
    if (_codec_type == 1) {
        coding_type = MPP_VIDEO_CodingHEVC;
    } else if (_codec_type == 0) {
        coding_type = MPP_VIDEO_CodingAVC;
    } else {
        fprintf(stderr, "[VPU] 未知编码类型 (%d)，初始化失败\n", _codec_type);
        return false;
    }
    ret = _p_mpp_init(_ctx, MPP_CTX_DEC, coding_type);
    if (ret != MPP_OK) {
        printf("mpp_init dec failed (%d), codec_type=%d\n", ret, _codec_type);
        _p_mpp_destroy(_ctx);
        _ctx = nullptr;
        _mpi = nullptr;
        return false;
    }

    RK_U32 immediate_out = 1;
    _mpi->control(_ctx, MPP_DEC_SET_IMMEDIATE_OUT, &immediate_out);

    RK_U32 fast_play = 1;
    _mpi->control(_ctx, MPP_DEC_SET_ENABLE_FAST_PLAY, &fast_play);

    MppFrameFormat out_fmt = MPP_FMT_YUV420SP;
    _mpi->control(_ctx, MPP_DEC_SET_OUTPUT_FORMAT, &out_fmt);

    RK_S64 block = 0;
    _mpi->control(_ctx, MPP_SET_OUTPUT_TIMEOUT, &block);

    ret = _p_mpp_packet_init(&_packet, nullptr, 0);
    if (ret != MPP_OK) {
        printf("mpp_packet_init failed (%d)\n", ret);
        if (_p_mpp_destroy && _ctx) {
            _p_mpp_destroy(_ctx);
        }
        _ctx = nullptr;
        _mpi = nullptr;
        return false;
    }

    _frm_grp = nullptr;
    _is_mpp_inited = true;
    _is_released = false;
    printf("vpu hardware decoder initialized (codec=%s, cmd_base=0x%08x).\n",
           (_codec_type == 1 ? "HEVC/H.265" : "AVC/H.264"), MPP_DEC_CMD_BASE);
    return true;
}

void VpuDecoder::release_mpp() {
    std::lock_guard<std::mutex> lock(_decode_mutex);
    release_mpp_internal();
}

void VpuDecoder::release_mpp_internal() {
    if (_is_released) {
        return;
    }
    if (_is_mpp_inited && _ctx && _mpi) {
        if (_mpi->reset) {
            _mpi->reset(_ctx);
        }
    }
    bool tmp_got = false;
    drain_frames(tmp_got);

    if (_packet && _p_mpp_packet_deinit) {
        _p_mpp_packet_deinit(&_packet);
        _packet = nullptr;
    }
    _current_buf_size = 0;
    if (_is_mpp_inited && _ctx) {
        if (_p_mpp_destroy) {
            _p_mpp_destroy(_ctx);
        }
        _ctx = nullptr;
        _mpi = nullptr;
        _is_mpp_inited = false;
    }
    if (_frm_grp) {
        if (_p_mpp_buffer_group_clear) {
            _p_mpp_buffer_group_clear(_frm_grp);
        }
        if (_p_mpp_buffer_group_put) {
            _p_mpp_buffer_group_put(_frm_grp);
        }
        _frm_grp = nullptr;
    }
    _is_released = true;
    if (_mpp_handle) {
        _mpp_handle = nullptr;
    }
    {
        std::lock_guard<std::mutex> lock(_frame_mutex);
        _latest_frame.reset();
        _write_frame.reset();
    }
    _raw_decode_buf.clear();
    _raw_decode_buf.shrink_to_fit();
    _pts_idx_queue.clear();
    _feed_buf.clear();
    _feed_buf.shrink_to_fit();
}

int VpuDecoder::probe_codec(const unsigned char* data, size_t size) {
    if (!data || size < 5) return -1;
    size_t scan_limit = (size > 8192) ? 8192 : size;
    for (size_t i = 0; i + 4 < scan_limit; ++i) {
        size_t nal_offset = 0;
        if (data[i] == 0 && data[i+1] == 0 && data[i+2] == 1) {
            nal_offset = i + 3;
        } else if (data[i] == 0 && data[i+1] == 0 && data[i+2] == 0 && data[i+3] == 1) {
            nal_offset = i + 4;
        }
        if (nal_offset > 0 && nal_offset + 1 < size) {
            unsigned char b0 = data[nal_offset];
            unsigned char b1 = data[nal_offset + 1];
            if ((b0 & 0x80) != 0) continue;

            // H.265 VPS(32: 0x40), SPS(33: 0x42), PPS(34: 0x44) with nuh_temporal_id_plus1 != 0
            if ((b0 == 0x40 || b0 == 0x42 || b0 == 0x44) && (b1 & 0x07) != 0) {
                return 1; // H.265 / HEVC
            }

            int h264_type = b0 & 0x1F;
            if (h264_type == 7 /* SPS */ || h264_type == 8 /* PPS */) {
                return 0; // H.264 / AVC
            }
        }
    }
    return -1;
}

void VpuDecoder::drain_frames(bool& got_new_frame) {
    if (!_is_mpp_inited || !_mpi || !_ctx) {
        return;
    }
    while (true) {
        MppFrame mpp_frame = nullptr;
        MPP_RET ret = _mpi->decode_get_frame(_ctx, &mpp_frame);
        if (ret != MPP_OK || !mpp_frame) {
            break;
        }

        uint32_t is_info_change = _p_mpp_frame_get_info_change ? _p_mpp_frame_get_info_change(mpp_frame) : 0;
        uint32_t errinfo = _p_mpp_frame_get_errinfo ? _p_mpp_frame_get_errinfo(mpp_frame) : 0;
        uint32_t discard = _p_mpp_frame_get_discard ? _p_mpp_frame_get_discard(mpp_frame) : 0;
        MppBuffer buffer = _p_mpp_frame_get_buffer ? _p_mpp_frame_get_buffer(mpp_frame) : nullptr;
        uint32_t width = _p_mpp_frame_get_width ? _p_mpp_frame_get_width(mpp_frame) : 0;
        uint32_t height = _p_mpp_frame_get_height ? _p_mpp_frame_get_height(mpp_frame) : 0;
        uint32_t hor_stride = _p_mpp_frame_get_hor_stride ? _p_mpp_frame_get_hor_stride(mpp_frame) : width;
        uint32_t ver_stride = _p_mpp_frame_get_ver_stride ? _p_mpp_frame_get_ver_stride(mpp_frame) : height;
        if (hor_stride == 0) hor_stride = width;
        if (ver_stride == 0) ver_stride = height;

        if (width > 8192 || height > 8192 || hor_stride > 16384 || ver_stride > 16384) {
            if (_p_mpp_frame_deinit) {
                _p_mpp_frame_deinit(&mpp_frame);
            }
            continue;
        }

        ++_frame_poll_count;

        if (is_info_change) {
            size_t buf_size = _p_mpp_frame_get_buf_size ? _p_mpp_frame_get_buf_size(mpp_frame) : 0;
            if (buf_size == 0) {
                buf_size = (size_t)hor_stride * ver_stride * 3 / 2;
            }
            printf("info change event #%d: %ux%u (stride: %ux%u, buf_size: %zu)\n",
                   _frame_poll_count, width, height, hor_stride, ver_stride, buf_size);

            if (_frm_grp != nullptr && buf_size != _current_buf_size) {
                if (_p_mpp_buffer_group_clear) {
                    _p_mpp_buffer_group_clear(_frm_grp);
                }
                if (_p_mpp_buffer_group_put) {
                    _p_mpp_buffer_group_put(_frm_grp);
                }
                _frm_grp = nullptr;
                _current_buf_size = 0;
            }

            if (_frm_grp == nullptr) {
                if (_p_mpp_buffer_group_get) {
                    _frm_grp = nullptr;
                    ret = _p_mpp_buffer_group_get(&_frm_grp, MPP_BUFFER_TYPE_DMA_HEAP, MPP_BUFFER_INTERNAL, NULL, NULL);
                    if (ret != MPP_OK || !_frm_grp) {
                        _frm_grp = nullptr;
                        ret = _p_mpp_buffer_group_get(&_frm_grp, MPP_BUFFER_TYPE_DRM, MPP_BUFFER_INTERNAL, NULL, NULL);
                    }
                    if (ret != MPP_OK || !_frm_grp) {
                        _frm_grp = nullptr;
                        ret = _p_mpp_buffer_group_get(&_frm_grp, MPP_BUFFER_TYPE_ION, MPP_BUFFER_INTERNAL, NULL, NULL);
                    }
                    if (ret != MPP_OK || !_frm_grp) {
                        _frm_grp = nullptr;
                        ret = _p_mpp_buffer_group_get(&_frm_grp, MPP_BUFFER_TYPE_NORMAL, MPP_BUFFER_INTERNAL, NULL, NULL);
                    }
                }
            }

            _current_buf_size = buf_size;
            RK_U32 stream_cnt = 0;
            RK_S32 buf_count = 8;
            if (_mpi->control(_ctx, MPP_DEC_GET_STREAM_COUNT, &stream_cnt) == MPP_OK && stream_cnt > 0) {
                buf_count = (RK_S32)(stream_cnt + 4);
                if (buf_count < 6) buf_count = 6;
                if (buf_count > 24) buf_count = 24;
            }
            if (_frm_grp && _p_mpp_buffer_group_limit_config) {
                _p_mpp_buffer_group_limit_config(_frm_grp, buf_size, buf_count);
            }

            if (_frm_grp) {
                _mpi->control(_ctx, MPP_DEC_SET_EXT_BUF_GROUP, _frm_grp);
            }
            _mpi->control(_ctx, MPP_DEC_SET_INFO_CHANGE_READY, nullptr);

            if (_p_mpp_frame_deinit) {
                _p_mpp_frame_deinit(&mpp_frame);
            }
            continue;
        }

        RK_S64 frame_pts = _p_mpp_frame_get_pts ? _p_mpp_frame_get_pts(mpp_frame) : -1;
        uint64_t actual_frame_idx = 0;
        int64_t actual_pts_ms = (frame_pts >= 0) ? (int64_t)frame_pts : 0;
        bool found_match = false;

        if (frame_pts >= 0) {
            for (auto it = _pts_idx_queue.begin(); it != _pts_idx_queue.end(); ++it) {
                if (it->first == (int64_t)frame_pts) {
                    actual_frame_idx = it->second;
                    actual_pts_ms = it->first;
                    _pts_idx_queue.erase(it);
                    found_match = true;
                    break;
                }
            }
            if (!_pts_idx_queue.empty() && (int64_t)frame_pts < _pts_idx_queue.front().first - 5000) {
                _pts_idx_queue.clear();
            } else {
                while (!_pts_idx_queue.empty() && _pts_idx_queue.front().first < (int64_t)frame_pts - 2000) {
                    _pts_idx_queue.pop_front();
                }
            }
        }
        if (!found_match) {
            if (!_pts_idx_queue.empty()) {
                actual_pts_ms = _pts_idx_queue.front().first;
                actual_frame_idx = _pts_idx_queue.front().second;
                _pts_idx_queue.pop_front();
                found_match = true;
                if (frame_pts >= 0) {
                    actual_pts_ms = (int64_t)frame_pts;
                }
            } else {
                actual_frame_idx = ++_fallback_seq;
            }
        }

        if (discard || (errinfo & 0x0f)) {
            if (_p_mpp_frame_deinit) {
                _p_mpp_frame_deinit(&mpp_frame);
            }
            continue;
        }

        if (buffer && width > 0 && height > 0) {
            void* ptr = get_buf_ptr(buffer, "drain_frames");
            int fd = get_buf_fd(buffer, "drain_frames");
            size_t buf_cap = get_buf_size(buffer, "drain_frames");
            size_t valid_sz = (size_t)hor_stride * ver_stride * 3 / 2;
            size_t copy_sz = valid_sz;
            if (buf_cap > 0 && copy_sz > buf_cap) {
                copy_sz = buf_cap;
            }

            void* mmap_ptr = nullptr;
            if (!ptr && fd >= 0 && copy_sz > 0) {
                mmap_ptr = mmap(nullptr, copy_sz, PROT_READ, MAP_SHARED, fd, 0);
                if (mmap_ptr != MAP_FAILED) {
                    ptr = mmap_ptr;
                } else {
                    mmap_ptr = nullptr;
                }
            }

            if (ptr && copy_sz > 0) {
                if (!_write_frame || _write_frame.use_count() > 1) {
                    _write_frame = std::make_shared<FrameBuffer>();
                    _write_frame->data.reserve(valid_sz);
                }
                _write_frame->data.resize(valid_sz);
                memcpy(_write_frame->data.data(), ptr, copy_sz);
                if (copy_sz < valid_sz) {
                    memset(_write_frame->data.data() + copy_sz, 0, valid_sz - copy_sz);
                }
                if (mmap_ptr) {
                    munmap(mmap_ptr, copy_sz);
                    mmap_ptr = nullptr;
                }
                _write_frame->width = (int)width;
                _write_frame->height = (int)height;
                _write_frame->hor_stride = (int)hor_stride;
                _write_frame->ver_stride = (int)ver_stride;
                _write_frame->frame_idx = actual_frame_idx;
                _write_frame->pts_ms = actual_pts_ms;

                {
                    std::lock_guard<std::mutex> lock(_frame_mutex);
                    std::swap(_latest_frame, _write_frame);
                }
                if (!_write_frame || _write_frame.use_count() > 1) {
                    _write_frame = std::make_shared<FrameBuffer>();
                    _write_frame->data.reserve(valid_sz);
                }
                got_new_frame = true;

                if (!_logged_first) {
                    MppFrameFormat fmt = _p_mpp_frame_get_fmt ? _p_mpp_frame_get_fmt(mpp_frame) : MPP_FMT_YUV420SP;
                    printf("first video frame decoded: %dx%d (stride: %dx%d, size: %zu, fmt=0x%08x)\n",
                           (int)width, (int)height, (int)hor_stride, (int)ver_stride, copy_sz, (unsigned int)fmt);
                    fflush(stdout);
                    _logged_first = true;
                }
            } else {
                if (_nobuf_cnt++ % 30 == 0) {
                    printf("frame #%d buffer valid but ptr=%p, fd=%d, size=%zu\n",
                           _frame_poll_count, ptr, fd, copy_sz);
                    fflush(stdout);
                }
            }
            if (mmap_ptr) {
                munmap(mmap_ptr, copy_sz);
                mmap_ptr = nullptr;
            }
        }

        if (_p_mpp_frame_deinit) {
            _p_mpp_frame_deinit(&mpp_frame);
        }
    }
}

bool VpuDecoder::decode_h264_packet(const unsigned char* _packetdata, size_t packet_size, image_buffer_t& frame, uint64_t frame_idx, int64_t pts_ms) {
    if (!feed_h264_packet(_packetdata, packet_size, frame_idx, pts_ms)) {
        return false;
    }
    std::lock_guard<std::mutex> lock(_decode_mutex);
    return get_latest_frame(_raw_decode_buf, frame, frame_idx, pts_ms);
}

bool VpuDecoder::feed_h264_packet(const unsigned char* _packetdata, size_t packet_size, uint64_t frame_idx, int64_t pts_ms) {
    std::lock_guard<std::mutex> lock(_decode_mutex);
    if (_is_released) {
        _is_released = false;
        _is_mpp_inited = false;
    }
    if (!_is_mpp_inited) {
        if (!init_mpp(_codec_type)) {
            return false;
        }
    }

    if (!_packetdata || packet_size == 0 || packet_size > 20 * 1024 * 1024 || !_mpi || !_packet) {
        return false;
    }

    const unsigned char* feed_ptr = _packetdata;
    size_t feed_size = packet_size;

    bool has_start_code = (packet_size >= 4 && _packetdata[0] == 0 && _packetdata[1] == 0 && _packetdata[2] == 0 && _packetdata[3] == 1) ||
                          (packet_size >= 3 && _packetdata[0] == 0 && _packetdata[1] == 0 && _packetdata[2] == 1);
    if (!has_start_code) {
        _feed_buf.clear();
        _feed_buf.reserve(packet_size + 4);
        _feed_buf.push_back(0x00);
        _feed_buf.push_back(0x00);
        _feed_buf.push_back(0x00);
        _feed_buf.push_back(0x01);
        _feed_buf.insert(_feed_buf.end(), _packetdata, _packetdata + packet_size);
        feed_ptr = _feed_buf.data();
        feed_size = _feed_buf.size();
    }

    if (_p_mpp_packet_set_data) _p_mpp_packet_set_data(_packet, const_cast<unsigned char*>(feed_ptr));
    if (_p_mpp_packet_set_size) _p_mpp_packet_set_size(_packet, feed_size);
    if (_p_mpp_packet_set_pos) _p_mpp_packet_set_pos(_packet, const_cast<unsigned char*>(feed_ptr));
    if (_p_mpp_packet_set_length) _p_mpp_packet_set_length(_packet, feed_size);
    if (_p_mpp_packet_set_pts) _p_mpp_packet_set_pts(_packet, (RK_S64)pts_ms);

    int put_ret = _mpi->decode_put_packet(_ctx, _packet);
    int retry = 0;
    while (put_ret == MPP_ERR_BUFFER_FULL && retry < 10) {
        bool tmp_got = false;
        drain_frames(tmp_got);
        usleep(2000);
        put_ret = _mpi->decode_put_packet(_ctx, _packet);
        retry++;
    }

    if (put_ret != MPP_OK) {
        return false;
    }

    if (frame_idx != UINT64_MAX && pts_ms >= 0) {
        if (_pts_idx_queue.empty() || (_pts_idx_queue.back().second != frame_idx && (_pts_idx_queue.back().first != pts_ms || pts_ms == 0))) {
            _pts_idx_queue.push_back({pts_ms, frame_idx});
            while (_pts_idx_queue.size() > 128) {
                _pts_idx_queue.pop_front();
            }
        } else {
            _pts_idx_queue.back().second = frame_idx;
            _pts_idx_queue.back().first = pts_ms;
        }
    }

    bool got_new_frame = false;
    drain_frames(got_new_frame);

    return true;
}

std::shared_ptr<VpuDecoder::FrameBuffer> VpuDecoder::get_latest_frame_snapshot() {
    std::lock_guard<std::mutex> lock(_frame_mutex);
    return _latest_frame;
}

bool VpuDecoder::letterbox_frame(const std::shared_ptr<FrameBuffer>& cur_frame, image_buffer_t* dst_img, letterbox_t* letter_box, int* orig_w, int* orig_h) {
    if (!cur_frame || cur_frame->data.empty() || cur_frame->width <= 0 || cur_frame->height <= 0) {
        return false;
    }
    if (!dst_img || !letter_box || !dst_img->virt_addr || dst_img->width <= 0 || dst_img->height <= 0) {
        return false;
    }

    int src_w = cur_frame->width;
    int src_h = cur_frame->height;
    int src_hor_stride = std::max(cur_frame->hor_stride, src_w);
    int src_ver_stride = std::max(cur_frame->ver_stride, src_h);

    size_t required_sz = (size_t)src_hor_stride * src_ver_stride * 3 / 2;
    if (cur_frame->data.size() < required_sz) {
        return false;
    }

    if (orig_w) *orig_w = src_w;
    if (orig_h) *orig_h = src_h;

    int dst_w = dst_img->width;
    int dst_h = dst_img->height;

    float scale = std::min((float)dst_w / (float)src_w, (float)dst_h / (float)src_h);
    int resize_w = (int)(src_w * scale);
    int resize_h = (int)(src_h * scale);
    resize_w = (resize_w / 2) * 2;
    resize_h = (resize_h / 2) * 2;
    int left = (dst_w - resize_w) / 2;
    int top = (dst_h - resize_h) / 2;
    left = (left / 2) * 2;
    top = (top / 2) * 2;
    if (left < 0) left = 0;
    if (top < 0) top = 0;
    if (left + resize_w > dst_w) resize_w = dst_w - left;
    if (top + resize_h > dst_h) resize_h = dst_h - top;

    letter_box->scale = scale;
    letter_box->x_pad = (float)left;
    letter_box->y_pad = (float)top;

    memset(dst_img->virt_addr, 114, (size_t)dst_w * dst_h * 3);

    int rga_ok = 0;
    if (src_w % 16 == 0 && dst_w % 16 == 0 && src_hor_stride % 16 == 0) {
        rga_buffer_t rga_src = wrapbuffer_virtualaddr(const_cast<unsigned char*>(cur_frame->data.data()), src_w, src_h, RK_FORMAT_YCbCr_420_SP, src_hor_stride, src_ver_stride);
        rga_buffer_t rga_dst = wrapbuffer_virtualaddr(dst_img->virt_addr, dst_w, dst_h, RK_FORMAT_RGB_888, dst_w, dst_h);
        im_rect srect = {0, 0, src_w, src_h};
        im_rect drect = {left, top, resize_w, resize_h};
        rga_buffer_t pat;
        memset(&pat, 0, sizeof(rga_buffer_t));
        im_rect prect = {0, 0, 0, 0};
        if (imcheck(rga_src, rga_dst, srect, drect) == IM_STATUS_NOERROR) {
            int ret_rga = improcess(rga_src, rga_dst, pat, srect, drect, prect, 0);
            if (ret_rga == IM_STATUS_SUCCESS || ret_rga > 0) {
                rga_ok = 1;
            }
        }
    }

    if (!rga_ok) {
        const unsigned char* y_plane = cur_frame->data.data();
        const unsigned char* uv_plane = y_plane + (size_t)src_hor_stride * src_ver_stride;
        unsigned char* dst_rgb = dst_img->virt_addr;

        float inv_scale = (scale > 0.0f) ? (1.0f / scale) : 1.0f;
        for (int dy = 0; dy < resize_h; ++dy) {
            int sy = (int)(dy * inv_scale);
            if (sy >= src_h) sy = src_h - 1;
            const unsigned char* py = y_plane + sy * src_hor_stride;
            const unsigned char* puv = uv_plane + (sy / 2) * src_hor_stride;
            unsigned char* pdst = dst_rgb + ((top + dy) * dst_w + left) * 3;

            for (int dx = 0; dx < resize_w; ++dx) {
                int sx = (int)(dx * inv_scale);
                if (sx >= src_w) sx = src_w - 1;

                int y_val = py[sx];
                int uv_idx = (sx / 2) * 2;
                if (uv_idx + 1 >= (int)src_hor_stride) {
                    uv_idx = (src_hor_stride >= 2) ? (int)(src_hor_stride - 2) : 0;
                }
                int u_val = puv[uv_idx];
                int v_val = puv[uv_idx + 1];

                int c = y_val - 16;
                int d = u_val - 128;
                int e = v_val - 128;

                int r = (298 * c + 409 * e + 128) >> 8;
                int g = (298 * c - 100 * d - 208 * e + 128) >> 8;
                int b = (298 * c + 516 * d + 128) >> 8;

                pdst[dx * 3 + 0] = (unsigned char)(r < 0 ? 0 : (r > 255 ? 255 : r));
                pdst[dx * 3 + 1] = (unsigned char)(g < 0 ? 0 : (g > 255 ? 255 : g));
                pdst[dx * 3 + 2] = (unsigned char)(b < 0 ? 0 : (b > 255 ? 255 : b));
            }
        }
    }

    return true;
}

bool VpuDecoder::letterbox_to_dst(image_buffer_t* dst_img, letterbox_t* letter_box, uint64_t& out_frame_idx, int64_t& out_pts_ms, int* orig_w, int* orig_h) {
    if (!dst_img || !letter_box || !dst_img->virt_addr || dst_img->width <= 0 || dst_img->height <= 0) {
        return false;
    }

    std::shared_ptr<FrameBuffer> cur_frame;
    {
        std::lock_guard<std::mutex> lock(_frame_mutex);
        cur_frame = _latest_frame;
    }

    if (!cur_frame || cur_frame->data.empty() || cur_frame->width <= 0 || cur_frame->height <= 0) {
        return false;
    }

    out_frame_idx = cur_frame->frame_idx;
    out_pts_ms = cur_frame->pts_ms;

    return letterbox_frame(cur_frame, dst_img, letter_box, orig_w, orig_h);
}

bool VpuDecoder::get_latest_frame(std::vector<unsigned char>& out_buffer, image_buffer_t& frame, uint64_t& out_frame_idx, int64_t& out_pts_ms) {
    std::shared_ptr<FrameBuffer> cur;
    {
        std::lock_guard<std::mutex> lock(_frame_mutex);
        cur = _latest_frame;
    }
    if (!cur || cur->data.empty() || cur->width <= 0 || cur->height <= 0) {
        return false;
    }
    size_t cur_sz = (size_t)cur->hor_stride * cur->ver_stride * 3 / 2;
    if (cur_sz == 0 || cur_sz > cur->data.size()) {
        cur_sz = cur->data.size();
    }
    if (out_buffer.size() < cur_sz) {
        out_buffer.resize(cur_sz);
    }
    memcpy(out_buffer.data(), cur->data.data(), cur_sz);

    memset(&frame, 0, sizeof(image_buffer_t));
    frame.width = cur->width;
    frame.height = cur->height;
    frame.width_stride = cur->hor_stride > 0 ? cur->hor_stride : cur->width;
    frame.height_stride = cur->ver_stride > 0 ? cur->ver_stride : cur->height;
    frame.format = IMAGE_FORMAT_YUV420SP_NV12;
    frame.virt_addr = out_buffer.data();
    frame.fd = -1;
    frame.size = (int)cur_sz;
    out_frame_idx = cur->frame_idx;
    out_pts_ms = cur->pts_ms;
    return true;
}

bool VpuDecoder::get_latest_frame(void* out_buffer, size_t out_buf_capacity, image_buffer_t& frame, uint64_t& out_frame_idx, int64_t& out_pts_ms) {
    if (!out_buffer || out_buf_capacity == 0) {
        return false;
    }
    std::shared_ptr<FrameBuffer> cur;
    {
        std::lock_guard<std::mutex> lock(_frame_mutex);
        cur = _latest_frame;
    }
    if (!cur || cur->data.empty() || cur->width <= 0 || cur->height <= 0) {
        return false;
    }
    size_t cur_sz = (size_t)cur->hor_stride * cur->ver_stride * 3 / 2;
    if (cur_sz == 0 || cur_sz > cur->data.size()) {
        cur_sz = cur->data.size();
    }
    if (out_buf_capacity < cur_sz) {
        return false;
    }
    memcpy(out_buffer, cur->data.data(), cur_sz);

    memset(&frame, 0, sizeof(image_buffer_t));
    frame.width = cur->width;
    frame.height = cur->height;
    frame.width_stride = cur->hor_stride > 0 ? cur->hor_stride : cur->width;
    frame.height_stride = cur->ver_stride > 0 ? cur->ver_stride : cur->height;
    frame.format = IMAGE_FORMAT_YUV420SP_NV12;
    frame.virt_addr = (unsigned char*)out_buffer;
    frame.fd = -1;
    frame.size = (int)cur_sz;
    out_frame_idx = cur->frame_idx;
    out_pts_ms = cur->pts_ms;
    return true;
}

uint64_t VpuDecoder::get_latest_frame_idx() {
    std::lock_guard<std::mutex> lock(_frame_mutex);
    return _latest_frame ? _latest_frame->frame_idx : UINT64_MAX;
}

void VpuDecoder::flush() {
    std::lock_guard<std::mutex> lk_dec(_decode_mutex);
    if (_is_released) {
        return;
    }
    std::lock_guard<std::mutex> lk_frm(_frame_mutex);
    _pts_idx_queue.clear();
    _feed_buf.clear();
    _latest_frame.reset();
    if (_write_frame) {
        _write_frame->width = 0;
        _write_frame->height = 0;
        _write_frame->frame_idx = 0;
        _write_frame->pts_ms = 0;
    }
    if (_is_mpp_inited && _mpi && _ctx) {
        if (_mpi->reset) {
            _mpi->reset(_ctx);
        }
        MppFrame frame = nullptr;
        while (_mpi->decode_get_frame(_ctx, &frame) == MPP_OK && frame) {
            if (_p_mpp_frame_deinit) {
                _p_mpp_frame_deinit(&frame);
            }
        }
    }
    printf("decoder state and queues flushed.\n");
}

bool VpuDecoder::decode_raw_buffer(const unsigned char* data, int width, int height, int channels, image_buffer_t& frame) {
    if (!data) {
        return false;
    }

    if (channels == 0) {
        size_t packet_size = (width > 0) ? (size_t)width : 0;
        bool ok = decode_h264_packet(data, packet_size, frame);
        if (!ok) {
            if (_dec_fail++ % 30 == 0) {
                printf("decode_h264_packet returned false (pkt_size=%zu, inited=%d, has_last_frame=%d)\n",
                       packet_size, (int)_is_mpp_inited, (int)(_latest_frame != nullptr));
                fflush(stdout);
            }
        }
        return ok;
    }

    if (width <= 0 || height <= 0) {
        return false;
    }

    memset(&frame, 0, sizeof(image_buffer_t));
    frame.width = width;
    frame.height = height;
    frame.width_stride = width;
    frame.height_stride = height;
    frame.virt_addr = const_cast<unsigned char*>(data);
    frame.fd = -1;

    if (channels == 12) {
        frame.format = IMAGE_FORMAT_YUV420SP_NV12;
    } else if (channels == 4) {
        frame.format = IMAGE_FORMAT_RGBA8888;
    } else if (channels == 1) {
        frame.format = IMAGE_FORMAT_GRAY8;
    } else {
        frame.format = IMAGE_FORMAT_RGB888;
    }
    frame.size = get_image_size(&frame);
    return true;
}
