use std::io::{Read, Write};
use std::os::linux::net::SocketAddrExt;
use std::os::unix::net::{SocketAddr, UnixStream};
use std::time::Duration;

pub const SOCKET_NAME: &[u8] = b"rk_detector_ipc";

pub const CMD_PING: u8 = 0x00;
pub const CMD_CREATE_CHANNEL: u8 = 0x01;
pub const CMD_RELEASE_CHANNEL: u8 = 0x02;
pub const CMD_FLUSH_CHANNEL: u8 = 0x03;
pub const CMD_FEED_PACKET: u8 = 0x04;
pub const CMD_DETECT_LATEST: u8 = 0x05;
pub const CMD_RELEASE_ALL: u8 = 0x06;

pub const RESP_PONG: u8 = 0x80;
pub const RESP_STATUS: u8 = 0x81;
pub const RESP_DETECT_RESULT: u8 = 0x82;

#[derive(Debug)]
pub struct IpcConnection {
    stream: UnixStream,
}

impl IpcConnection {
    pub fn connect() -> std::io::Result<Self> {
        let addr = SocketAddr::from_abstract_name(SOCKET_NAME)?;
        let stream = UnixStream::connect_addr(&addr)?;
        stream.set_read_timeout(Some(Duration::from_secs(3)))?;
        stream.set_write_timeout(Some(Duration::from_secs(3)))?;
        Ok(Self { stream })
    }

    pub fn send_request(&mut self, cmd: u8, payload: &[u8]) -> std::io::Result<()> {
        let payload_len = payload.len() as u32;
        self.stream.write_all(&payload_len.to_be_bytes())?;
        self.stream.write_all(&[cmd])?;
        if !payload.is_empty() {
            self.stream.write_all(payload)?;
        }
        self.stream.flush()?;
        Ok(())
    }

    pub fn read_response(&mut self) -> std::io::Result<(u8, Vec<u8>)> {
        let mut hdr = [0u8; 5];
        self.stream.read_exact(&mut hdr)?;
        let payload_len = u32::from_be_bytes([hdr[0], hdr[1], hdr[2], hdr[3]]) as usize;
        let resp_cmd = hdr[4];

        if payload_len > 10 * 1024 * 1024 {
            return Err(std::io::Error::new(
                std::io::ErrorKind::InvalidData,
                "ipc 响应载荷超出限制",
            ));
        }

        let mut payload = vec![0u8; payload_len];
        if payload_len > 0 {
            self.stream.read_exact(&mut payload)?;
        }
        Ok((resp_cmd, payload))
    }

    pub fn ping(&mut self) -> std::io::Result<()> {
        self.send_request(CMD_PING, &[])?;
        let (resp_cmd, _) = self.read_response()?;
        if resp_cmd == RESP_PONG {
            Ok(())
        } else {
            Err(std::io::Error::new(
                std::io::ErrorKind::Other,
                format!("意外的 ping 响应: {resp_cmd:#x}"),
            ))
        }
    }
}
