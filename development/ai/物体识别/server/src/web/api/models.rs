use axum::{
    extract::State,
    Json,
};
use serde_json::{json, Value};
use std::sync::Arc;
use crate::web_rtc::WebRtcServer;
use crate::detector::ipc::detect_wrapper::ModelItem;

pub async fn get_models(State(server): State<Arc<WebRtcServer>>) -> Json<Value> {
    let mut models = server.list_models();
    if models.is_empty() {
        models = vec![
            ModelItem {
                id: "gen".to_string(),
                name: "通用检测".to_string(),
                classes: vec![
                    "person".to_string(), "bicycle".to_string(), "car".to_string(), "motorcycle".to_string(),
                    "airplane".to_string(), "bus".to_string(), "train".to_string(), "truck".to_string(),
                    "boat".to_string(), "traffic light".to_string(), "fire hydrant".to_string(), "stop sign".to_string(),
                    "parking meter".to_string(), "bench".to_string(), "bird".to_string(), "cat".to_string(),
                    "dog".to_string(), "horse".to_string(), "sheep".to_string(), "cow".to_string(),
                    "elephant".to_string(), "bear".to_string(), "zebra".to_string(), "giraffe".to_string(),
                    "backpack".to_string(), "umbrella".to_string(), "handbag".to_string(), "tie".to_string(),
                    "suitcase".to_string(), "frisbee".to_string(), "skis".to_string(), "snowboard".to_string(),
                    "sports ball".to_string(), "kite".to_string(), "baseball bat".to_string(), "baseball glove".to_string(),
                    "skateboard".to_string(), "surfboard".to_string(), "tennis racket".to_string(), "bottle".to_string(),
                    "wine glass".to_string(), "cup".to_string(), "fork".to_string(), "knife".to_string(),
                    "spoon".to_string(), "bowl".to_string(), "banana".to_string(), "apple".to_string(),
                    "sandwich".to_string(), "orange".to_string(), "broccoli".to_string(), "carrot".to_string(),
                    "hot dog".to_string(), "pizza".to_string(), "donut".to_string(), "cake".to_string(),
                    "chair".to_string(), "couch".to_string(), "potted plant".to_string(), "bed".to_string(),
                    "dining table".to_string(), "toilet".to_string(), "tv".to_string(), "laptop".to_string(),
                    "mouse".to_string(), "remote".to_string(), "keyboard".to_string(), "cell phone".to_string(),
                    "microwave".to_string(), "oven".to_string(), "toaster".to_string(), "sink".to_string(),
                    "refrigerator".to_string(), "book".to_string(), "clock".to_string(), "vase".to_string(),
                    "scissors".to_string(), "teddy bear".to_string(), "hair drier".to_string(), "toothbrush".to_string(),
                ],
            },
            ModelItem {
                id: "industry".to_string(),
                name: "工业检测".to_string(),
                classes: vec![
                    "person".to_string(), "hardhat".to_string(), "no-hardhat".to_string(), "safety-vest".to_string(),
                    "no-safety-vest".to_string(), "safety-harness".to_string(), "no-safety-harness".to_string(),
                    "gloves".to_string(), "safety-shoes".to_string(), "mask".to_string(), "no-mask".to_string(),
                    "goggles".to_string(), "smoking".to_string(), "cigarette".to_string(), "phone-call".to_string(),
                    "cellphone".to_string(), "fall-down".to_string(), "sleeping".to_string(), "gathering".to_string(),
                    "climbing".to_string(), "forklift".to_string(), "truck".to_string(), "excavator".to_string(),
                    "crane".to_string(), "pallet".to_string(), "traffic-cone".to_string(), "warning-sign".to_string(),
                    "fire".to_string(), "smoke".to_string(), "fire-extinguisher".to_string(), "blocked-escape".to_string(),
                ],
            },
            ModelItem {
                id: "anfang".to_string(),
                name: "安防".to_string(),
                classes: vec!["helmet".to_string(), "no-helmet".to_string(), "no-vest".to_string(), "person".to_string(), "vest".to_string()],
            },
            ModelItem {
                id: "chache".to_string(),
                name: "叉车".to_string(),
                classes: vec!["forklift".to_string(), "person".to_string()],
            },
            ModelItem {
                id: "chepai".to_string(),
                name: "车牌".to_string(),
                classes: vec!["license_plate".to_string()],
            },
        ];
    }
    Json(json!({
        "status": "ok",
        "models": models,
        "groups": models
    }))
}
