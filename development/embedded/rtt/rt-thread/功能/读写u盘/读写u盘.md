# 读写 u 盘

## 说明

使用 usb host 读写 u 盘

参考 [这里](https://www.rt-thread.org/document/site/application-note/driver/usb/an0046-rtthread-driver-usbh/)

## 步骤

### usb host

```sh
打开 cubeMX，配置 USB_OTG, 使用 host_only 模式，nvic interrupt table 配置 usb on the go fs global interrupt, 生成代码，复制到项目

cubeMX 里面配置的时候，rcc 需要启用 hse，外部晶震，usb 的时钟需要设置为 48MHZ
复制 main.c 里面的时钟配置到 board.c
```

修改 board/Kconfig，添加

```sh
config BSP_USING_USBH
    bool "Enable USB host"
    select RT_USING_USB_HOST
    default n
```

```sh
RT-Thread Components --->
  Device Drivers --->
    Using USB --->
      [*] Using USB host
      [*] Enable Udisk Drivers
      (/)   Udisk mount dir
```

### 文件系统

位置

```sh
RT-Thread Components --->
  Device virtual file system --->
    [*]Using device virtual file system
      [*] Enable elm-chan fatfs
        elm-chan's FatFs, Generic FAT Filesystem Module  --->
        (4096) Maximum sector size to be handled.
```

### libc

```sh
RT-Thread Components --->
  POSIX layer and C standard library --->
    [*] Enable libc APIs from toolchain
```

### 复制驱动

去 gitee 的 rt thread 的 master 分支里面找到 drv_usbh.c 和 drv_usbh.h， 放到项目的 libraries/HAL_Drivers 里面

修改，添加 libraries/HAL_Drivers/SConscript

```txt
if GetDepend(['BSP_USING_USBH']):
    src += ['drv_usbh.c']
```

## 备注

u 盘的供电需要 `5v`

可以修改 usb 调试宏查看日志 RT_DEBUG_USB
