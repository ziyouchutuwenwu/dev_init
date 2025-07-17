# openocd 编译

下载源码编译
github 的脚本比较多,建议 [github 版](https://github.com/ntfreak/openocd)

## 编译

安装需要的库

```sh
sudo apt install autoconf libtool pkg-config libusb-1.0-0-dev libftdi-dev libhidapi-dev libgpiod-dev
```

构建

```sh
cd openocd_github_src
autoupdate
./bootstrap
./configure --enable-jlink --prefix=$HOME/dev/embedded/openocd/openocd
make install
make clean
```

## 注意

如果提示错误

```sh
configure: error: Internal libjaylink not found, run either 'git submodule init' and 'git submodule update' or disable internal libjaylink with --disable-internal-libjaylink.
```

则

```sh
rm -rf src/jtag/drivers/libjaylink
git submodule update --recursive
```

## 用法

```sh
openocd -f interface/jlink.cfg -c "transport select swd" -f target/stm32h7x.cfg
```
