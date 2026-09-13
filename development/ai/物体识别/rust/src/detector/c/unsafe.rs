use std::os::raw::{c_char, c_int, c_uchar};

unsafe extern "C" {
    pub fn init(total_streams: c_int) -> c_int;

    pub fn bin_to_img_stream(
        ch: c_int,
        packet_data: *const c_uchar,
        packet_size: c_int,
        frame_idx: u64,
        pts_ms: i64,
    ) -> c_int;

    pub fn detect_img_bin(
        ch: c_int,
        out_buf: *mut c_char,
        out_buf_size: c_int,
        out_frame_idx: *mut u64,
        out_pts_ms: *mut i64,
    ) -> c_int;
}