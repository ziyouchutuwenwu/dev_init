#pragma once

#include <vector>
#include <cstdint>
#include <memory>

typedef void* MppBuffer;

struct FrameBuffer {
    std::vector<unsigned char> data;
    int width = 0;
    int height = 0;
    int hor_stride = 0;
    int ver_stride = 0;
    uint64_t frame_idx = 0;
    int64_t pts_ms = 0;
    int dma_fd = -1;
    MppBuffer mpp_buf = nullptr;
    std::shared_ptr<void> group_holder = nullptr;

    FrameBuffer() = default;
    ~FrameBuffer();
    FrameBuffer(const FrameBuffer&) = delete;
    FrameBuffer& operator=(const FrameBuffer&) = delete;
    FrameBuffer(FrameBuffer&&) = default;
    FrameBuffer& operator=(FrameBuffer&&) = default;
};
