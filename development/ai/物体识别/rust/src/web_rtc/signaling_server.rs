use super::WebRtcServer;
use std::sync::Arc;
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tokio::net::{TcpListener, TcpStream};

pub struct SignalingServer;

impl SignalingServer {
    pub fn resolve_stream_id(server: &WebRtcServer, path: &str) -> Option<String> {
        if let Some(query_idx) = path.find('?') {
            let query = &path[query_idx + 1..];
            for pair in query.split('&') {
                if let Some((k, v)) = pair.split_once('=') {
                    if (k == "src" || k == "stream" || k == "id") && !v.is_empty() {
                        let decoded = v.replace("%2F", "/");
                        if server.streams().contains_key(&decoded) {
                            return Some(decoded);
                        }
                    }
                }
            }
        }

        let raw_path = path.split('?').next().unwrap_or(path);
        let raw_path = raw_path.trim_end_matches('/');

        let sub = raw_path.strip_prefix('/').unwrap_or(raw_path);
        if let Some(seg) = sub.strip_prefix("offer/") {
            if server.streams().contains_key(seg) {
                return Some(seg.to_string());
            }
        }
        if !sub.is_empty() && sub != "offer" && sub != "health" && sub != "streams" && sub != "api" {
            if server.streams().contains_key(sub) {
                return Some(sub.to_string());
            }
            return Some(sub.to_string());
        }

        server.default_stream_id().cloned()
    }

    pub async fn run_with_listener(server: Arc<WebRtcServer>, listener: TcpListener) -> std::io::Result<()> {
        loop {
            let (conn, addr) = match listener.accept().await {
                Ok(res) => res,
                Err(e) => {
                    eprintln!("[signaling] 接受连接失败: {e}");
                    continue;
                }
            };
            let server = Arc::clone(&server);
            tokio::spawn(async move {
                Self::handle_connection(server, conn, addr).await;
            });
        }
    }

    pub async fn run(server: Arc<WebRtcServer>) -> std::io::Result<()> {
        let http_addr = server.http_addr();
        let listener = TcpListener::bind(http_addr).await?;
        Self::run_with_listener(server, listener).await
    }

    async fn handle_connection(
        server: Arc<WebRtcServer>,
        mut conn: TcpStream,
        addr: std::net::SocketAddr,
    ) {
        let mut buf: Vec<u8> = Vec::new();
        let mut tmp = [0u8; 4096];
        let header_end = loop {
            let n = match conn.read(&mut tmp).await {
                Ok(0) | Err(_) => return,
                Ok(n) => n,
            };
            buf.extend_from_slice(&tmp[..n]);
            if let Some(pos) = buf.windows(4).position(|w| w == b"\r\n\r\n") {
                break pos + 4;
            }
            if buf.len() > (1 << 20) {
                return;
            }
        };

        let headers = String::from_utf8_lossy(&buf[..header_end]);
        let first_line = headers.lines().next().unwrap_or("");
        let mut parts = first_line.split_whitespace();
        let method = parts.next().unwrap_or("");
        let path = parts.next().unwrap_or("");

        let content_length = headers
            .lines()
            .find_map(|l| {
                l.trim()
                    .to_ascii_lowercase()
                    .strip_prefix("content-length:")
                    .and_then(|v| v.trim().parse::<usize>().ok())
            })
            .unwrap_or(0);

        if method == "OPTIONS" {
            let resp = concat!(
                "HTTP/1.1 204 No Content\r\n",
                "Access-Control-Allow-Origin: *\r\n",
                "Access-Control-Allow-Methods: POST, GET, OPTIONS\r\n",
                "Access-Control-Allow-Headers: Content-Type, *\r\n",
                "Access-Control-Max-Age: 86400\r\n",
                "Connection: close\r\n",
                "Content-Length: 0\r\n\r\n"
            );
            let _ = conn.write_all(resp.as_bytes()).await;
            let _ = conn.flush().await;
            let _ = conn.shutdown().await;
            return;
        }

        if method == "GET" && path == "/health" {
            let resp = "HTTP/1.1 200 OK\r\nAccess-Control-Allow-Origin: *\r\nConnection: close\r\nContent-Length: 2\r\n\r\nok";
            let _ = conn.write_all(resp.as_bytes()).await;
            let _ = conn.flush().await;
            let _ = conn.shutdown().await;
            return;
        }

        if method == "POST" {
            let stream_id_opt = Self::resolve_stream_id(&server, path);
            let stream_id = match stream_id_opt {
                Some(id) => id,
                None => {
                    eprintln!("[signaling] [{addr}] 未找到指定的流: {path}，可用流: {:?}", server.stream_order());
                    let msg = format!("未找到指定的流。可用流列表: {:?}", server.stream_order());
                    let resp = format!(
                        "HTTP/1.1 404 Not Found\r\nAccess-Control-Allow-Origin: *\r\nConnection: close\r\nContent-Type: text/plain; charset=utf-8\r\nContent-Length: {}\r\n\r\n{msg}",
                        msg.len()
                    );
                    let _ = conn.write_all(resp.as_bytes()).await;
                    let _ = conn.flush().await;
                    let _ = conn.shutdown().await;
                    return;
                }
            };

            if content_length > 0 && buf.len() < header_end + content_length {
                let read_res = tokio::time::timeout(std::time::Duration::from_millis(2500), async {
                    while buf.len() < header_end + content_length {
                        match conn.read(&mut tmp).await {
                            Ok(0) | Err(_) => return false,
                            Ok(n) => buf.extend_from_slice(&tmp[..n]),
                        }
                    }
                    true
                }).await;

                if read_res != Ok(true) {
                    eprintln!("[signaling] [{addr}] 读取请求体超时或连接已关闭");
                    return;
                }
            }

            let body = if buf.len() >= header_end + content_length {
                String::from_utf8_lossy(&buf[header_end..header_end + content_length]).to_string()
            } else {
                String::from_utf8_lossy(&buf[header_end..]).to_string()
            };

            match server.handle_offer(&stream_id, &body).await {
                Ok(answer_sdp) => {
                    let resp = format!(
                        "HTTP/1.1 200 OK\r\nAccess-Control-Allow-Origin: *\r\nAccess-Control-Allow-Headers: Content-Type, *\r\nAccess-Control-Allow-Methods: POST, GET, OPTIONS\r\nConnection: close\r\nContent-Type: application/sdp\r\nContent-Length: {}\r\n\r\n{}",
                        answer_sdp.len(),
                        answer_sdp
                    );
                    let _ = conn.write_all(resp.as_bytes()).await;
                    let _ = conn.flush().await;
                    let _ = conn.shutdown().await;
                }
                Err(e) => {
                    eprintln!("[signaling] [{addr}] Offer 处理失败 (stream={stream_id}): {e}");
                    let msg = format!("Offer 处理失败 (stream={stream_id}): {e}");
                    let resp = format!(
                        "HTTP/1.1 500 Internal Server Error\r\nAccess-Control-Allow-Origin: *\r\nAccess-Control-Allow-Headers: Content-Type, *\r\nConnection: close\r\nContent-Type: text/plain; charset=utf-8\r\nContent-Length: {}\r\n\r\n{msg}",
                        msg.len()
                    );
                    let _ = conn.write_all(resp.as_bytes()).await;
                    let _ = conn.flush().await;
                    let _ = conn.shutdown().await;
                }
            }
        } else {
            eprintln!("[signaling] [{addr}] 收到非 POST/OPTIONS/GET 请求: {method}");
            let resp = "HTTP/1.1 404 Not Found\r\nAccess-Control-Allow-Origin: *\r\nConnection: close\r\nContent-Length: 0\r\n\r\n";
            let _ = conn.write_all(resp.as_bytes()).await;
            let _ = conn.flush().await;
            let _ = conn.shutdown().await;
        }
    }
}
