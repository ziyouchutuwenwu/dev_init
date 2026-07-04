# esp32

## 说明

openocd 用 [厂商定制版](https://github.com/espressif/openocd-esp32/releases)

## 准备

启用 jtag

```sh
espefuse -p /dev/ttyACM0 burn-efuse STRAP_JTAG_SEL
```

测试

```sh
# esp_usb_bridge.cfg 里面 vid_pid
# 对应 lsusb 的 vendor_id 和 product_id
openocd -f interface/esp_usb_bridge.cfg -f target/esp32s3.cfg
```
