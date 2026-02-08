# sysbuild

## 说明

一般用于 ota

## 步骤

### 准备

```sh
uv pip install cbor
```

### 编译

sysbuild.conf

```conf
SB_CONFIG_BOOTLOADER_MCUBOOT=y
```

可选

sysbuild/mcuboot.conf

```conf
# rsa 签名
CONFIG_BOOT_SIGNATURE_TYPE_RSA=y

# 禁止降级
CONFIG_BOOT_UPGRADE_ONLY=y

# log level
CONFIG_MCUBOOT_LOG_LEVEL_INF=y
```

prj.conf

```conf
# mcuboot 作为 bootloader
CONFIG_BOOTLOADER_MCUBOOT=y

# 镜像管理与 ota 写入支持
CONFIG_IMG_MANAGER=y
CONFIG_STREAM_FLASH=y
CONFIG_IMG_ERASE_PROGRESSIVELY=y

# mcumgr 核心功能
CONFIG_MCUMGR=y
CONFIG_MCUMGR_GRP_IMG=y
CONFIG_MCUMGR_GRP_OS=y

# mcumgr 串口传输
CONFIG_MCUMGR_TRANSPORT_UART=y
CONFIG_MCUMGR_TRANSPORT_UART_MTU=512
CONFIG_UART_MCUMGR=y

# 禁用串口控制台，避免与 mcumgr 冲突
# CONFIG_UART_CONSOLE is not set

# mcumgr 依赖
CONFIG_NET_BUF=y
CONFIG_ZCBOR=y
CONFIG_BASE64=y
CONFIG_CRC=y
CONFIG_STATS=y

# Flash 支持
CONFIG_FLASH=y
CONFIG_FLASH_MAP=y
CONFIG_FLASH_PAGE_LAYOUT=y

# 日志
CONFIG_LOG=y
CONFIG_MCUMGR_LOG_LEVEL_INF=y
```

编译

```sh
west build -b esp32s3_devkitc/esp32s3/procpu -p always -d build/debug --sysbuild
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
