pub mod math;
pub mod model;
#[allow(clippy::module_inception)]
pub mod tracker;

pub use math::{calculate_iou, euclidean_dist};
pub use model::{DetectionInput, TrackedObject, TrackerConfig};
pub use tracker::ObjectTracker;
