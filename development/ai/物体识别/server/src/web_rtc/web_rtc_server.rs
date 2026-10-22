use super::peer_manager::PeerManager;
use super::signaling_server::SignalingServer;
use super::stream_context::StreamContext;
use crate::detector::DetectWrapper;
use std::collections::HashMap;
use std::sync::atomic::AtomicU64;
use std::sync::Arc;
use tokio::sync::Mutex;
use webrtc::peer_connection::PeerConnection;

pub struct RunningStream {
    pub stream_id: String,
    pub input_url: String,
    pub channel_id: u32,
    pub ai_enabled: bool,
    pub model: String,
    pub context: StreamContext,
    pub handle: tokio::task::JoinHandle<()>,
}

pub struct WebRtcServer {
    http_addr: String,
    detect_wrapper: Arc<DetectWrapper>,
    running_streams: Arc<std::sync::RwLock<HashMap<String, RunningStream>>>,
    stream_order: Arc<std::sync::RwLock<Vec<String>>>,
    active_connections: Arc<Mutex<HashMap<u64, Arc<dyn PeerConnection>>>>,
    next_conn_id: AtomicU64,
}

impl WebRtcServer {
    pub fn new(
        http_addr: impl Into<String>,
        detect_wrapper: Arc<DetectWrapper>,
        initial_streams: Vec<RunningStream>,
    ) -> Self {
        let mut map = HashMap::new();
        let mut order = Vec::new();

        for s in initial_streams {
            order.push(s.stream_id.clone());
            map.insert(s.stream_id.clone(), s);
        }

        Self {
            http_addr: http_addr.into(),
            detect_wrapper,
            running_streams: Arc::new(std::sync::RwLock::new(map)),
            stream_order: Arc::new(std::sync::RwLock::new(order)),
            active_connections: Arc::new(Mutex::new(HashMap::new())),
            next_conn_id: AtomicU64::new(1),
        }
    }

    pub fn http_addr(&self) -> &str {
        &self.http_addr
    }

    pub fn streams(&self) -> HashMap<String, StreamContext> {
        self.running_streams
            .read()
            .unwrap()
            .iter()
            .map(|(k, v)| (k.clone(), v.context.clone()))
            .collect()
    }

    pub fn stream_order(&self) -> Vec<String> {
        self.stream_order.read().unwrap().clone()
    }

    pub fn default_stream_id(&self) -> Option<String> {
        self.stream_order.read().unwrap().first().cloned()
    }

    pub fn has_stream(&self, id: &str) -> bool {
        self.running_streams.read().unwrap().contains_key(id)
    }

    pub fn get_stream_context(&self, id: &str) -> Option<StreamContext> {
        self.running_streams.read().unwrap().get(id).map(|s| s.context.clone())
    }

    pub async fn handle_offer(&self, stream_id: &str, offer_sdp: &str) -> Result<String, String> {
        let stream_ctx = match self.get_stream_context(stream_id) {
            Some(ctx) => ctx,
            None => {
                let order = self.stream_order();
                return Err(format!(
                    "未找到指定的流 ID '{}'。当前已加载的可用流: {:?}",
                    stream_id, order
                ));
            }
        };

        PeerManager::handle_offer(
            &stream_ctx,
            offer_sdp,
            &self.active_connections,
            &self.next_conn_id,
        )
        .await
    }

    pub fn get_stream_ai_enabled(&self, stream_id: &str) -> Option<bool> {
        let running = self.running_streams.read().unwrap();
        running.get(stream_id).map(|s| s.ai_enabled)
    }

    pub fn get_stream_model(&self, stream_id: &str) -> Option<String> {
        let running = self.running_streams.read().unwrap();
        running.get(stream_id).map(|s| s.model.clone())
    }

    pub fn stop_all_streams(&self) {
        let mut map = self.running_streams.write().unwrap();
        for (_, s) in map.drain() {
            log::info!("[server] 停止流 [{}] 协程 (ch={})", s.stream_id, s.channel_id);
            s.handle.abort();
        }
        self.stream_order.write().unwrap().clear();
    }

    pub async fn update_streams(
        &self,
        new_streams_list: Vec<crate::config::StreamConfig>,
    ) -> Result<(), String> {
        let mut to_stop = Vec::new();
        let mut to_start = Vec::new();

        {
            let running = self.running_streams.read().unwrap();
            let new_map: HashMap<&str, &crate::config::StreamConfig> = new_streams_list
                .iter()
                .map(|s| (s.id.as_str(), s))
                .collect();

            for (id, stream) in running.iter() {
                match new_map.get(id.as_str()) {
                    Some(&new_cfg) => {
                        if stream.input_url != new_cfg.input
                            || stream.ai_enabled != new_cfg.enabled
                            || stream.model != new_cfg.model
                        {
                            to_stop.push(id.clone());
                            to_start.push(new_cfg.clone());
                        }
                    }
                    None => {
                        to_stop.push(id.clone());
                    }
                }
            }

            for s in &new_streams_list {
                if !running.contains_key(&s.id) {
                    to_start.push(s.clone());
                }
            }
        }

        for id in to_stop {
            let removed = {
                let mut running = self.running_streams.write().unwrap();
                running.remove(&id)
            };
            if let Some(stream) = removed {
                log::info!("[stream_manager] 热更新停止流 [{}] (ch={}, model={})", stream.stream_id, stream.channel_id, stream.model);
                stream.handle.abort();
                let _ = self.detect_wrapper.release_channel(stream.channel_id);
                crate::on_detected::ObjectTrackHandler::remove_context(&stream.stream_id);
            }
        }

        if !to_start.is_empty() {
            tokio::time::sleep(tokio::time::Duration::from_millis(100)).await;
        }

        for stream_cfg in to_start {
            let ch_idx = {
                let running = self.running_streams.read().unwrap();
                let used: std::collections::HashSet<u32> =
                    running.values().map(|s| s.channel_id).collect();
                let mut c = 0u32;
                while used.contains(&c) {
                    c += 1;
                }
                c
            };

            let id = stream_cfg.id.clone();
            let url = stream_cfg.input.clone();
            let en = stream_cfg.enabled;
            let model = stream_cfg.model.clone();

            log::info!("[stream_manager] 热更新启动流 [{}] (ch={}, url={}, ai={}, model={})", id, ch_idx, url, en, model);

            match crate::prepare::setup_single_stream(
                ch_idx,
                stream_cfg,
                Arc::clone(&self.detect_wrapper),
            )
            .await
            {
                Ok((stream_ctx, handle)) => {
                    let running_stream = RunningStream {
                        stream_id: id.clone(),
                        input_url: url,
                        channel_id: ch_idx,
                        ai_enabled: en,
                        model,
                        context: stream_ctx,
                        handle,
                    };
                    let mut running = self.running_streams.write().unwrap();
                    running.insert(id, running_stream);
                }
                Err(e) => {
                    log::error!("[stream_manager] 热更新启动流 [{}] 失败: {e}", id);
                }
            }
        }

        {
            let mut order = self.stream_order.write().unwrap();
            order.clear();
            for s in &new_streams_list {
                order.push(s.id.clone());
            }
        }

        log::info!("[stream_manager] 流配置热更新完成，当前有效流列表: {:?}", self.stream_order());
        Ok(())
    }

    pub async fn run_signaling_server(self: Arc<Self>) -> std::io::Result<()> {
        SignalingServer::run(self).await
    }

    pub async fn run_signaling_server_with_listener(self: Arc<Self>, listener: tokio::net::TcpListener) -> std::io::Result<()> {
        SignalingServer::run_with_listener(self, listener).await
    }
}
