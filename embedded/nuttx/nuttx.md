# nuttx 教程

## 编译需要的库

```bash
sudo apt install gcc-arm-none-eabi ncurses-dev gperf flex bison libtool
```

## 源码地址

```bash
git clone https://bitbucket.org/patacongo/nuttx.git
git clone https://bitbucket.org/nuttx/tools.git
git clone https://bitbucket.org/patacongo/apps.git
```

### 编译 需要的工具和 so 库

```bash
cd tools/kconfig-frontends
autoreconf -f -i
./configure --enable-mconf --prefix=$HOME/downloads/nuttx-libs
make install
```

### 编译 nuttx

#### 把工具和库添加到环境变量

```bash
export PATH=$HOME/nuttx/nuttx-build-essential/bin:$PATH
export LD_LIBRARY_PATH=$HOME/nuttx/nuttx-build-essential/lib:$LD_LIBRARY_PATH
```

```bash
cd nuttx/tools
./configure.sh stm32f103-minimum/nsh
cd ..
make menuconfig
make
```
