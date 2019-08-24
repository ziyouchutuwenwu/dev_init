# 参考地址

```bash
https://blog.jetbrains.com/clion/2017/12/clion-for-embedded-development-part-ii/
```

## 准备工作

- stm32CubeMX
- openocd
- gcc-arm-none-eabi
- clion

## stm32CubeMX，自己搜索下载

## 准备编译 openocd，里面的 jlink 支持需要 libusb-1.0.0-dev

```bash
sudo apt install libusb-1.0.0-dev
sudo apt install libhidapi-dev
sudo apt install pkg-config automake libtool
```

## openocd 编译

```bash
./configure --enable-jlink --enable-cmsis-dap --prefix=$HOME/dev/embedded/stm32/openocd; make; make install
```

## 复制规则到/etc/udev/rules.d/，否则 idea 调试会出问题，提示失败；复制以后，插拔 daplink 或者 jlink 生效

```bash
sudo cp $OPENOCD_DIR/contrib/60-openocd.rules /etc/udev/rules.d/
```

## 编写开发板的调试配置文件

### daplink_board.cfg

```bash
source [find interface/cmsis-dap.cfg]
transport select swd
source [find target/stm32f1x.cfg]
```

### daplink.sh

```bash
#! /usr/bin/env /bin/bash

CURRENT_DIR=$(cd "$(dirname "$0")";pwd)
$CURRENT_DIR/bin/openocd -f $CURRENT_DIR/daplink_board.cfg
```

### jlink_board.cfg

```bash
source [find interface/jlink.cfg]
transport select swd
source [find target/stm32f1x.cfg]
```

### jlink.sh

```bash
#! /usr/bin/env /bin/bash

CURRENT_DIR=$(cd "$(dirname "$0")";pwd)
$CURRENT_DIR/bin/openocd -f $CURRENT_DIR/jlink_board.cfg
```

## 编译器

```bash
sudo apt install gcc-arm-none-eabi
```

## stm32CubeMX 建立工程, 建立模板使用 sw4stm32 的

## 去 jlink 官网下载 debian 下的 jlink 驱动（其实主要是为了 JFlashLite，别的不需要）

- https://www.segger.com/downloads/jlink/#J-LinkSoftwareAndDocumentationPack

## clion

- 需要设置好 openocd 和 STM32CubeMX 的路径

## 开发板挂了

- 开发板如果挂了，最后使用 JFlashLite 重新 erase 解决的

## 调试步骤

- stm32CubeMX 里面，一定要在 sys，debug，选 serial wire，否则，项目在第一行 main 入口可以中断，但是，在第二行就无法中断，而且会无法 erase，调试的时候只能调试一次，折腾了好久才解决。其实这个设置以后，就是通过内置电路，在需要擦除主板固件的时候会擦除。
- 调试配置里面，就是默认的 elf 文件
- Board config file：就是我们刚才建立的 daplink_board.cfg 和 jlink_board.cfg
- 如果点击 debug 没有反应，记得按一下开发板上的 reset，重启，会马上中断；可以通过 daplink 上绿灯旁边的那个灯来判断，如果那个灯快速闪烁，就说明可以中断，否则，无法中断。
- clion 里面 build 生成的 bin 文件是最终程序，可以是用 JFlashLite 烧录，手动亲测通过。
