# openocd 编译

下载源码编译
github 的脚本比较多,建议 [github 版](https://github.com/ntfreak/openocd)

## 编译

一定要安装下面的库, 否则无法找到设备

```bash
sudo apt install libusb-1.0-0-dev
```

```bash
./bootstrap
./configure --enable-jlink --prefix=$HOME/dev/embedded/openocd/openocd
make install
```

## 用法

```bash
openocd -f interface/jlink.cfg -c "transport select swd" -f target/stm32h7x.cfg
```
