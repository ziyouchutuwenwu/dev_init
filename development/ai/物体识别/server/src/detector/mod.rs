pub mod detection_result;
pub mod frame_detector;
pub mod raw_detect_response;
pub mod ipc;

pub use detection_result::{DetectionItem, DetectionObject, DetectionResult};
pub use frame_detector::FrameDetector;
pub use raw_detect_response::RawDetectResponse;
pub use ipc::DetectWrapper;
