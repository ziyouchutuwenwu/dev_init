#include "hardware/frame_buffer.h"
#include "hardware/vpu_decoder.h"

FrameBuffer::~FrameBuffer() {
    if (mpp_buf) {
        VpuDecoder::mpp_buf_put(mpp_buf);
        mpp_buf = nullptr;
    }
}
