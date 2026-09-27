pub mod detect_wrapper;
pub mod ipc_connection;

pub use detect_wrapper::DetectWrapper;
pub use ipc_connection::{
    IpcConnection, CMD_CREATE_CHANNEL, CMD_DETECT_LATEST, CMD_FEED_PACKET, CMD_FLUSH_CHANNEL,
    CMD_PING, CMD_RELEASE_ALL, CMD_RELEASE_CHANNEL, RESP_DETECT_RESULT, RESP_PONG, RESP_STATUS,
    SOCKET_NAME,
};
