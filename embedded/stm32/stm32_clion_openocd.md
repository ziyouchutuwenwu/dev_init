# 参考地址
```
https://blog.jetbrains.com/clion/2017/12/clion-for-embedded-development-part-ii/
```

## 准备工作：
  - stm32CubeMX
  - openocd
  - gcc-arm-none-eabi
  - clion

## stm32CubeMX，需要安装32位运行库
```
sudo apt-get install libc6:i386
```

## 准备编译openocd，里面的jlink支持需要libusb-1.0.0-dev
```
sudo apt install libusb-1.0.0-dev
sudo apt install libhidapi-dev
sudo apt install pkg-config automake libtool
```

## openocd编译
```
./configure --enable-jlink --enable-cmsis-dap --prefix=$HOME/dev/embedded/stm32/openocd; make; make install
```
## 复制规则到/etc/udev/rules.d/，否则idea调试会出问题，提示失败；复制以后，插拔daplink或者jlink生效
```
sudo cp $OPENOCD_DIR/contrib/60-openocd.rules /etc/udev/rules.d/
```

## 编写开发板的调试配置文件
### daplink_board.cfg
```
source [find interface/cmsis-dap.cfg]
transport select swd
source [find target/stm32f1x.cfg]
```

### daplink.sh
```
#! /usr/bin/env /bin/bash

CURRENT_DIR=$(cd "$(dirname "$0")";pwd)
$CURRENT_DIR/bin/openocd -f $CURRENT_DIR/daplink_board.cfg
```

### jlink_board.cfg
```
source [find interface/jlink.cfg]
transport select swd
source [find target/stm32f1x.cfg]
```

### jlink.sh
```
#! /usr/bin/env /bin/bash

CURRENT_DIR=$(cd "$(dirname "$0")";pwd)
$CURRENT_DIR/bin/openocd -f $CURRENT_DIR/jlink_board.cfg
```

## 编译器
```
sudo apt install gcc-arm-none-eabi
```

## stm32CubeMX建立工程, 建立模板使用sw4stm32的

## 去jlink官网下载debian下的jlink驱动（其实主要是为了JFlashLite，别的不需要）
- https://www.segger.com/downloads/jlink/#J-LinkSoftwareAndDocumentationPack

## clion
- 需要设置好openocd和STM32CubeMX的路径

## 开发板挂了
- 开发板如果挂了，最后使用JFlashLite重新erase解决的

## 调试步骤
- stm32CubeMX里面，一定要在sys，debug，选serial wire，否则，项目在第一行main入口可以中断，但是，在第二行就无法中断，而且会无法erase，调试的时候只能调试一次，折腾了好久才解决。其实这个设置以后，就是通过内置电路，在需要擦除主板固件的时候会擦除。
- 调试配置里面，就是默认的elf文件
- Board config file：就是我们刚才建立的daplink_board.cfg和jlink_board.cfg
- 如果点击debug没有反应，记得按一下开发板上的reset，重启，会马上中断；可以通过daplink上绿灯旁边的那个灯来判断，如果那个灯快速闪烁，就说明可以中断，否则，无法中断。
- clion里面build生成的bin文件是最终程序，可以是用JFlashLite烧录，手动亲测通过。