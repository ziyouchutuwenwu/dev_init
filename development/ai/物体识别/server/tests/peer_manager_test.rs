use server::web_rtc::{is_h264_keyframe, is_h265_keyframe, is_video_keyframe};

#[test]
fn test_is_h264_keyframe() {
    assert!(is_h264_keyframe(&[0, 0, 0, 1, 0x67, 0x42, 0x00, 0x1e]));
    assert!(is_h264_keyframe(&[0, 0, 1, 0x65, 0x88, 0x84, 0x00]));
    assert!(!is_h264_keyframe(&[0, 0, 0, 1, 0x61, 0x9a, 0x00, 0x00]));
    assert!(!is_h264_keyframe(&[1, 2, 3, 4, 5]));
}

#[test]
fn test_is_h265_keyframe() {
    assert!(is_h265_keyframe(&[0, 0, 0, 1, 0x40, 0x01]));
    assert!(is_h265_keyframe(&[0, 0, 1, 0x26, 0x01]));
    assert!(!is_h265_keyframe(&[0, 0, 0, 1, 0x02, 0x01]));
    assert!(is_video_keyframe(&[0, 0, 0, 1, 0x40, 0x01]));
}
