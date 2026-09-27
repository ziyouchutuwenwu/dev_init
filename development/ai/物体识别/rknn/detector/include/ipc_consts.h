#ifndef IPC_CONSTS_H
#define IPC_CONSTS_H

#include <stdint.h>

#define DEFAULT_SOCKET_NAME "rk_detector_ipc"
#define IPC_MAX_PAYLOAD_LEN (10 * 1024 * 1024)
#define IPC_HEADER_LEN 5

enum IpcCmdType : uint8_t {
    CMD_PING            = 0x00,
    CMD_CREATE_CHANNEL  = 0x01,
    CMD_RELEASE_CHANNEL = 0x02,
    CMD_FLUSH_CHANNEL   = 0x03,
    CMD_FEED_PACKET     = 0x04,
    CMD_DETECT_LATEST   = 0x05,
    CMD_RELEASE_ALL     = 0x06,

    RESP_PONG           = 0x80,
    RESP_STATUS         = 0x81,
    RESP_DETECT_RESULT  = 0x82,
    RESP_ERROR          = 0xFF,
};

#endif