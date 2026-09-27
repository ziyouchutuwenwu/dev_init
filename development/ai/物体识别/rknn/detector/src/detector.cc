#include "detector.h"
#include "ipc_consts.h"
#include "engine/engine.h"
#include "channel/channel.h"
#include "channel/channel_manager.h"
#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>
#include <signal.h>
#include <endian.h>
#include <cstring>
#include <cstdio>
#include <cerrno>
#include <atomic>
#include <thread>
#include <vector>
#include <mutex>
#include <algorithm>
#include <string>

static std::atomic<bool> g_running{true};
static std::atomic<int> g_active_clients{0};
static std::mutex g_clients_mutex;
static std::vector<int> g_client_fds;

static void register_client(int fd) {
    std::lock_guard<std::mutex> lock(g_clients_mutex);
    g_client_fds.push_back(fd);
}

static void unregister_client(int fd) {
    std::lock_guard<std::mutex> lock(g_clients_mutex);
    auto it = std::find(g_client_fds.begin(), g_client_fds.end(), fd);
    if (it != g_client_fds.end()) {
        g_client_fds.erase(it);
    }
}

static void shutdown_all_clients() {
    std::lock_guard<std::mutex> lock(g_clients_mutex);
    for (int fd : g_client_fds) {
        shutdown(fd, SHUT_RDWR);
    }
}

static void sig_handler(int sig) {
    (void)sig;
    g_running = false;
}

static bool read_exact(int fd, void* buf, size_t n) {
    size_t total = 0;
    char* p = static_cast<char*>(buf);
    int retry_count = 0;
    while (total < n) {
        if (!g_running) {
            return false;
        }
        ssize_t ret = read(fd, p + total, n - total);
        if (ret <= 0) {
            if (ret < 0 && (errno == EINTR || errno == EAGAIN || errno == EWOULDBLOCK)) {
                if (total > 0 && ++retry_count > 5) {
                    return false;
                }
                continue;
            }
            return false;
        }
        total += static_cast<size_t>(ret);
        retry_count = 0;
    }
    return true;
}

static bool write_exact(int fd, const void* buf, size_t n) {
    size_t total = 0;
    const char* p = static_cast<const char*>(buf);
    int retry_count = 0;
    while (total < n) {
        if (!g_running) {
            return false;
        }
        ssize_t ret = write(fd, p + total, n - total);
        if (ret <= 0) {
            if (ret < 0 && (errno == EINTR || errno == EAGAIN || errno == EWOULDBLOCK)) {
                if (++retry_count > 5) {
                    return false;
                }
                usleep(1000);
                continue;
            }
            return false;
        }
        total += static_cast<size_t>(ret);
        retry_count = 0;
    }
    return true;
}

struct ClientSessionGuard {
    int fd;
    explicit ClientSessionGuard(int f) : fd(f) {
        g_active_clients++;
        register_client(fd);
    }
    ~ClientSessionGuard() {
        unregister_client(fd);
        close(fd);
        g_active_clients--;
    }
    ClientSessionGuard(const ClientSessionGuard&) = delete;
    ClientSessionGuard& operator=(const ClientSessionGuard&) = delete;
};

static void handle_client(int client_fd) {
    ClientSessionGuard guard(client_fd);

    struct timeval tv;
    tv.tv_sec = 1;
    tv.tv_usec = 0;
    setsockopt(client_fd, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv));

    struct timeval snd_tv;
    snd_tv.tv_sec = 3;
    snd_tv.tv_usec = 0;
    setsockopt(client_fd, SOL_SOCKET, SO_SNDTIMEO, &snd_tv, sizeof(snd_tv));

    try {
        std::vector<uint8_t> payload_buf;
        std::vector<char> detect_out_buf(65536);
        std::vector<uint8_t> resp_buf;

        while (g_running) {
            uint8_t hdr[IPC_HEADER_LEN];
            if (!read_exact(client_fd, hdr, IPC_HEADER_LEN)) {
                break;
            }

            uint32_t payload_len = 0;
            memcpy(&payload_len, hdr, 4);
            payload_len = be32toh(payload_len);
            uint8_t cmd = hdr[4];

            if (payload_len > IPC_MAX_PAYLOAD_LEN) {
                fprintf(stderr, "接收到超长异常报文: %u 字节，断开连接\n", payload_len);
                break;
            }

            if (payload_buf.size() < payload_len) {
                payload_buf.resize(payload_len);
            }

            if (payload_len > 0) {
                if (!read_exact(client_fd, payload_buf.data(), payload_len)) {
                    break;
                }
            }

            switch (cmd) {
                case CMD_PING: {
                    uint8_t resp[5];
                    uint32_t resp_len = htobe32(0);
                    memcpy(resp, &resp_len, 4);
                    resp[4] = RESP_PONG;
                    if (!write_exact(client_fd, resp, 5)) goto exit_loop;
                    break;
                }

                case CMD_CREATE_CHANNEL: {
                    if (payload_len <= 4) goto err_resp;
                    uint32_t ch = 0;
                    memcpy(&ch, payload_buf.data(), 4);
                    ch = be32toh(ch);

                    std::string codec_name(reinterpret_cast<char*>(payload_buf.data() + 4), payload_len - 4);
                    std::string lower_codec = codec_name;
                    std::transform(lower_codec.begin(), lower_codec.end(), lower_codec.begin(), ::tolower);

                    int codec_type = -1;
                    if (lower_codec.find("264") != std::string::npos || lower_codec.find("avc") != std::string::npos) {
                        codec_type = 0;
                    } else if (lower_codec.find("265") != std::string::npos || lower_codec.find("hevc") != std::string::npos) {
                        codec_type = 1;
                    } else {
                        fprintf(stderr, "[detector] 错误: 通道 %u 请求了不支持的编码格式: %s (仅支持 h264/h265)\n", ch, codec_name.c_str());
                    }

                    int ret = -1;
                    if (codec_type >= 0) {
                        printf("[detector] 收到创建通道指令: 通道=%u, 编码格式=%s\n", ch, codec_name.c_str());
                        auto channel = ChannelManager::instance().create_one(static_cast<int>(ch), codec_type);
                        ret = channel ? 0 : -1;
                    }

                    uint8_t resp[9];
                    uint32_t resp_len = htobe32(4);
                    int32_t status_val = htobe32(ret);
                    memcpy(resp, &resp_len, 4);
                    resp[4] = RESP_STATUS;
                    memcpy(resp + 5, &status_val, 4);
                    if (!write_exact(client_fd, resp, 9)) goto exit_loop;
                    break;
                }

                case CMD_RELEASE_CHANNEL: {
                    if (payload_len < 4) goto err_resp;
                    uint32_t ch = 0;
                    memcpy(&ch, payload_buf.data(), 4);
                    ch = be32toh(ch);
                    int ret = ChannelManager::instance().release_one(static_cast<int>(ch));

                    uint8_t resp[9];
                    uint32_t resp_len = htobe32(4);
                    int32_t status_val = htobe32(ret);
                    memcpy(resp, &resp_len, 4);
                    resp[4] = RESP_STATUS;
                    memcpy(resp + 5, &status_val, 4);
                    if (!write_exact(client_fd, resp, 9)) goto exit_loop;
                    break;
                }

                case CMD_FLUSH_CHANNEL: {
                    if (payload_len < 4) goto err_resp;
                    uint32_t ch = 0;
                    memcpy(&ch, payload_buf.data(), 4);
                    ch = be32toh(ch);
                    int ret = ChannelManager::instance().flush_one(static_cast<int>(ch));

                    uint8_t resp[9];
                    uint32_t resp_len = htobe32(4);
                    int32_t status_val = htobe32(ret);
                    memcpy(resp, &resp_len, 4);
                    resp[4] = RESP_STATUS;
                    memcpy(resp + 5, &status_val, 4);
                    if (!write_exact(client_fd, resp, 9)) goto exit_loop;
                    break;
                }

                case CMD_FEED_PACKET: {
                    if (payload_len < 20) goto err_resp;
                    uint32_t ch = 0;
                    uint64_t frame_idx = 0;
                    int64_t pts_ms = 0;
                    memcpy(&ch, payload_buf.data(), 4);
                    memcpy(&frame_idx, payload_buf.data() + 4, 8);
                    memcpy(&pts_ms, payload_buf.data() + 12, 8);
                    ch = be32toh(ch);
                    frame_idx = be64toh(frame_idx);
                    pts_ms = be64toh(pts_ms);
                    const unsigned char* packet_data = payload_buf.data() + 20;
                    int packet_size = static_cast<int>(payload_len - 20);

                    auto channel = ChannelManager::instance().get(static_cast<int>(ch));
                    if (!channel) {
                        channel = ChannelManager::instance().create_one(static_cast<int>(ch));
                    }
                    int ret = channel ? channel->bin_to_img_stream(packet_data, packet_size, frame_idx, pts_ms) : -1;

                    uint8_t resp[9];
                    uint32_t resp_len = htobe32(4);
                    int32_t status_val = htobe32(ret);
                    memcpy(resp, &resp_len, 4);
                    resp[4] = RESP_STATUS;
                    memcpy(resp + 5, &status_val, 4);
                    if (!write_exact(client_fd, resp, 9)) goto exit_loop;
                    break;
                }

                case CMD_DETECT_LATEST: {
                    if (payload_len < 4) goto err_resp;
                    uint32_t ch = 0;
                    memcpy(&ch, payload_buf.data(), 4);
                    ch = be32toh(ch);

                    unsigned long long out_frame_idx = 0;
                    long long out_pts_ms = 0;
                    auto channel = ChannelManager::instance().get(static_cast<int>(ch));
                    if (!channel) {
                        channel = ChannelManager::instance().create_one(static_cast<int>(ch));
                    }
                    int ret = channel ? channel->detect_img_bin(
                        detect_out_buf.data(),
                        static_cast<int>(detect_out_buf.size()),
                        &out_frame_idx,
                        &out_pts_ms
                    ) : -1;

                    uint32_t json_len = (ret > 0) ? static_cast<uint32_t>(ret) : 0;
                    if (json_len > detect_out_buf.size()) {
                        json_len = static_cast<uint32_t>(detect_out_buf.size());
                    }
                    uint32_t resp_payload_len = 4 + 8 + 8 + 4 + json_len;
                    size_t total_resp_len = 5 + resp_payload_len;

                    if (resp_buf.size() < total_resp_len) {
                        resp_buf.resize(total_resp_len);
                    }
                    uint32_t net_resp_len = htobe32(resp_payload_len);
                    memcpy(resp_buf.data(), &net_resp_len, 4);
                    resp_buf[4] = RESP_DETECT_RESULT;

                    int32_t status = (ret >= 0) ? 0 : ret;
                    int32_t net_status = htobe32(status);
                    uint64_t net_idx = htobe64(out_frame_idx);
                    int64_t net_pts = htobe64(out_pts_ms);
                    uint32_t net_json_len = htobe32(json_len);

                    memcpy(resp_buf.data() + 5, &net_status, 4);
                    memcpy(resp_buf.data() + 9, &net_idx, 8);
                    memcpy(resp_buf.data() + 17, &net_pts, 8);
                    memcpy(resp_buf.data() + 25, &net_json_len, 4);

                    if (json_len > 0) {
                        memcpy(resp_buf.data() + 29, detect_out_buf.data(), json_len);
                    }

                    if (!write_exact(client_fd, resp_buf.data(), total_resp_len)) goto exit_loop;
                    break;
                }

                case CMD_RELEASE_ALL: {
                    int ret = ChannelManager::instance().release_all();
                    uint8_t resp[9];
                    uint32_t resp_len = htobe32(4);
                    int32_t status_val = htobe32(ret);
                    memcpy(resp, &resp_len, 4);
                    resp[4] = RESP_STATUS;
                    memcpy(resp + 5, &status_val, 4);
                    if (!write_exact(client_fd, resp, 9)) goto exit_loop;
                    break;
                }

                default:
                err_resp: {
                    uint8_t resp[5];
                    uint32_t resp_len = htobe32(0);
                    memcpy(resp, &resp_len, 4);
                    resp[4] = RESP_ERROR;
                    if (!write_exact(client_fd, resp, 5)) goto exit_loop;
                    break;
                }
            }
        }

    exit_loop:
        ;
    } catch (const std::exception& e) {
        fprintf(stderr, "客户端处理异常: %s\n", e.what());
    } catch (...) {
        fprintf(stderr, "客户端处理未知异常\n");
    }
}

int run_detector(const char* socket_name) {
    if (!socket_name || socket_name[0] == '\0') {
        socket_name = DEFAULT_SOCKET_NAME;
    }

    struct sigaction sa;
    memset(&sa, 0, sizeof(sa));
    sa.sa_handler = sig_handler;
    sigemptyset(&sa.sa_mask);
    sa.sa_flags = 0;
    sigaction(SIGINT, &sa, nullptr);
    sigaction(SIGTERM, &sa, nullptr);
    signal(SIGPIPE, SIG_IGN);

    Engine::instance().init();

    int server_fd = socket(AF_UNIX, SOCK_STREAM, 0);
    if (server_fd < 0) {
        perror("socket 创建失败");
        Engine::instance().deinit();
        return 1;
    }

    struct sockaddr_un addr;
    memset(&addr, 0, sizeof(addr));
    addr.sun_family = AF_UNIX;
    addr.sun_path[0] = '\0';
    size_t name_len = strlen(socket_name);
    if (name_len > sizeof(addr.sun_path) - 2) {
        name_len = sizeof(addr.sun_path) - 2;
    }
    memcpy(addr.sun_path + 1, socket_name, name_len);

    socklen_t addr_len = offsetof(struct sockaddr_un, sun_path) + 1 + name_len;

    if (bind(server_fd, reinterpret_cast<struct sockaddr*>(&addr), addr_len) < 0) {
        perror("bind 抽象命名空间失败");
        close(server_fd);
        Engine::instance().deinit();
        return 1;
    }

    if (listen(server_fd, 64) < 0) {
        perror("listen 失败");
        close(server_fd);
        Engine::instance().deinit();
        return 1;
    }

    while (g_running) {
        int client_fd = accept(server_fd, nullptr, nullptr);
        if (client_fd < 0) {
            if (!g_running || errno == EINTR) break;
            continue;
        }
        try {
            std::thread(handle_client, client_fd).detach();
        } catch (const std::exception& e) {
            fprintf(stderr, "创建客户端工作线程失败: %s\n", e.what());
            close(client_fd);
        } catch (...) {
            fprintf(stderr, "创建客户端工作线程发生未知错误\n");
            close(client_fd);
        }
    }

    printf("\n正在退出，释放硬件资源...\n");
    shutdown(server_fd, SHUT_RDWR);
    close(server_fd);
    shutdown_all_clients();
    int wait_count = 0;
    while (g_active_clients.load() > 0 && wait_count++ < 100) {
        usleep(50000);
    }
    Engine::instance().deinit();
    printf("退出完成。\n");
    return 0;
}
