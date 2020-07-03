# 单片机作为 u 盘

## 打开 usb device

- 打开 cubeMX，配置 USB_OTG, 使用 host_device 模式，nvic interrupt table 配置 usb on the go fs global interrupt, 生成代码，复制到项目
- cubeMX 里面配置的时候，rcc 需要启用 hse，外部晶震，usb 的时钟需要设置为 48MHZ
- 复制 main.c 里面的时钟配置到 board.c
- 修改 board/Kconfig，添加

```bash
config BSP_USING_USBD
    bool "Enable USB device"
    select RT_USING_USB_DEVICE
    default n
```

```bash
RT-Thread Components --->
    Device Drivers --->
      Using USB --->
        [*] Using USB device
        [*] Enable composite device
        [*] Enable to use device as Mass Storage device
        (自己改名字) msc class disk name
```

## 以下参考 sdio 的配置
