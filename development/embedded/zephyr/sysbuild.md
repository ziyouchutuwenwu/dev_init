# sysbuild

## 说明

一般用于 ota

## 步骤

### 准备

```sh
uv pip install cbor
```

### 配置

sysbuild.conf

```conf
SB_CONFIG_BOOTLOADER_MCUBOOT=y
```

可选

sysbuild/mcuboot.conf

```conf
# rsa 签名
CONFIG_BOOT_SIGNATURE_TYPE_RSA=y

CONFIG_BOOT_UPGRADE_ONLY=y
CONFIG_MCUBOOT_LOG_LEVEL_INF=y
```

prj_mcumgr.conf

```conf
# 依赖项
CONFIG_NET_BUF=y
CONFIG_ZCBOR=y
CONFIG_BASE64=y
CONFIG_CRC=y

# 镜像
CONFIG_IMG_MANAGER=y
CONFIG_STREAM_FLASH=y
CONFIG_IMG_ERASE_PROGRESSIVELY=y

# mcumgr 核心
CONFIG_MCUMGR=y
CONFIG_MCUMGR_GRP_IMG=y
CONFIG_MCUMGR_GRP_OS=y

# mcumgr 串口传输
CONFIG_MCUMGR_TRANSPORT_UART_MTU=512
CONFIG_MCUMGR_TRANSPORT_UART=y
CONFIG_UART_MCUMGR=y

# flash 支持
CONFIG_FLASH=y
CONFIG_FLASH_MAP=y
CONFIG_FLASH_PAGE_LAYOUT=y

# 日志
CONFIG_LOG=y
CONFIG_MCUMGR_LOG_LEVEL_INF=y

# 下载完固件后触发升级
CONFIG_REBOOT=y
```

prj_http.conf

```conf
# 镜像
CONFIG_IMG_MANAGER=y
CONFIG_STREAM_FLASH=y
CONFIG_IMG_ERASE_PROGRESSIVELY=y

# 网络
CONFIG_NETWORKING=y
CONFIG_NET_IPV4=y
CONFIG_NET_TCP=y
CONFIG_NET_SOCKETS=y
CONFIG_DNS_RESOLVER=y
CONFIG_HTTP_CLIENT=y
CONFIG_NET_SOCKETS_SOCKOPT_TLS=y
CONFIG_TLS_CREDENTIALS=y

# mbedtls
CONFIG_MBEDTLS=y
CONFIG_MBEDTLS_BUILTIN=y
CONFIG_MBEDTLS_CFG_FILE="config-mbedtls.h"
CONFIG_MBEDTLS_SSL_PROTO_TLS1_2=y
CONFIG_MBEDTLS_KEY_EXCHANGE_PSK_ENABLED=y

# flash 支持
CONFIG_FLASH=y
CONFIG_FLASH_MAP=y
CONFIG_FLASH_PAGE_LAYOUT=y

# 日志 + 重启
CONFIG_LOG=y
CONFIG_REBOOT=y
```

boards/esp32s3_devkitc.overlay

```c
&uart0 {
  current-speed = <115200>;
};

/ {
  chosen {
    // CONFIG_UART_MCUMGR 需要这里的 zephyr,uart-mcumgr
    zephyr,uart-mcumgr = &uart0;
  };
};
```

### 编译

```sh
west build -b esp32s3_devkitc/esp32s3/procpu \
    -d build/release \
    --sysbuild \
    -- \
    -DCMAKE_BUILD_TYPE=Release \
    -DOVERLAY_CONFIG=prj_http.conf
```

```sh
west build -b esp32s3_devkitc/esp32s3/procpu \
    -d build/release \
    --sysbuild \
    -- \
    -DCMAKE_BUILD_TYPE=Release \
    -DOVERLAY_CONFIG=prj_mcumgr.conf
```

### 测试

准备

```sh
go install github.com/apache/mynewt-mcumgr-cli/mcumgr@latest
```

上传

```sh
mcumgr \
  --conntype serial \
  --connstring "dev=/dev/ttyACM0,mtu=512" \
  image upload ~/downloads/board_led/build/debug/board_led/zephyr/zephyr.signed.bin
```

新的固件在 slot1 里面，正常情况下，flags 为空

```sh
mcumgr \
  --conntype serial \
  --connstring "dev=/dev/ttyACM0,mtu=512" \
  image list

# test 只能处理非 active 的
mcumgr \
  --conntype serial \
  --connstring "dev=/dev/ttyACM0,mtu=512" \
  image test 242a26504988c804c5c9c1ae6dbea2b37128e0c59abe26f8cb4726e671a1451f

# 重启 mcu
mcumgr \
  --conntype serial \
  --connstring "dev=/dev/ttyACM0,mtu=512" \
  reset

# 确认
mcumgr \
  --conntype serial \
  --connstring "dev=/dev/ttyACM0,mtu=512" \
  image confirm 242a26504988c804c5c9c1ae6dbea2b37128e0c59abe26f8cb4726e671a1451f
```
