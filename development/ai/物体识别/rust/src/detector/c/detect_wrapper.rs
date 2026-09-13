use std::ffi::CStr;
use std::os::raw::{c_char, c_int};
use super::r#unsafe::{bin_to_img_stream, detect_img_bin, init};

#[derive(Default, Debug, Clone, Copy)]
pub struct DetectWrapper;

pub type DetectCWrapper = DetectWrapper;

impl DetectWrapper {
    pub fn new() -> Self {
        Self
    }

    pub fn init(&self, total_streams: u32) -> Result<(), String> {
        unsafe {
            let ret = init(total_streams as c_int);
            if ret < 0 {
                return Err(format!("init failed with code: {ret}"));
            }
            Ok(())
        }
    }

    pub fn bin_to_img_stream(&self, ch: u32, packet_data: &[u8], frame_idx: u64, pts_ms: i64) -> Result<(), String> {
        if packet_data.is_empty() {
            return Ok(());
        }

        unsafe {
            let ret = bin_to_img_stream(
                ch as c_int,
                packet_data.as_ptr(),
                packet_data.len() as c_int,
                frame_idx,
                pts_ms,
            );

            if ret < 0 {
                return Err(format!("bin_to_img_stream (ch={ch}) returned error code: {ret}"));
            }
            Ok(())
        }
    }

    pub fn detect_img_bin(&self, ch: u32) -> Result<(String, u64, i64), String> {
        unsafe {
            let mut buffer = vec![0u8; 65536];
            let mut out_frame_idx: u64 = 0;
            let mut out_pts_ms: i64 = 0;

            let ret = detect_img_bin(
                ch as c_int,
                buffer.as_mut_ptr() as *mut c_char,
                buffer.len() as c_int,
                &mut out_frame_idx,
                &mut out_pts_ms,
            );

            if ret < 0 {
                return Err(format!("detect_img_bin (ch={ch}) returned error code: {ret}"));
            }

            let c_str = CStr::from_ptr(buffer.as_ptr() as *const c_char);
            let result_str = c_str.to_string_lossy().into_owned();
            Ok((result_str, out_frame_idx, out_pts_ms))
        }
    }
}
