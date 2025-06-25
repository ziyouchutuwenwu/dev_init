# 当成 u 盘

## 说明

单片机作为 u 盘

## 步骤

### 打开 usb

```sh
打开 cubeMX，配置 USB_OTG, 使用 host_device 模式，nvic interrupt table 配置 usb on the go fs global interrupt, 生成代码，复制到项目

cubeMX 里面配置的时候，rcc 需要启用 hse，外部晶震，usb 的时钟需要设置为 48MHZ

复制 main.c 里面的时钟配置到 board.c
```

修改 board/Kconfig，添加

```sh
config BSP_USING_USBD
    bool "Enable USB device"
    select RT_USING_USB_DEVICE
    default n
```

```sh
RT-Thread Components --->
  Device Drivers --->
    Using USB --->
      [*] Using USB device
      [*] Enable composite device
      [*] Enable to use device as Mass Storage device
      (自己改名字) msc class disk name
```

### 其他配置

参考 sdio 的配置，即可将 sd 卡插在 stm32 上，在电脑上显示出来

sd 卡的文件系统用 fat 和 ntfs 都可以
