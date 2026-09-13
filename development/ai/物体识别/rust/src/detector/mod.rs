pub mod c;
pub mod detection_result;
pub mod frame_detector;

pub use c::{DetectCWrapper, DetectWrapper};
pub use detection_result::{DetectionItem, DetectionObject, DetectionResult};
pub use frame_detector::FrameDetector;