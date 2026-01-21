# bitbake

## 说明

bitbake 是封装过的构建工具

根据 BBPATH 找到 bitbake.conf 和 bblayers.conf 的路径

根据 bblayers.conf 里面的配置，找到一个个 layer

继续从 layer 里面找到 recipe 并执行

## 激活环境

source 以后，才可以用 bitbake

```sh
# 默认会创建 build 目录
source oe-init-build-env
```

```sh
# 最如果需要编译多个环境，可以指定环境
source oe-init-build-env build_aarch64
```

## 配置说明

build/conf/local.conf

```sh
GIT_CLONE_DEPTH = "1"

# 构建完成后会自动删除中间文件，保留 sstate 缓存、下载的源码包
INHERIT += "rm_work"
```

## 命令说明

| 命令                    | 说明                     |
| ----------------------- | ------------------------ |
| core-image-minimal      | 最小命令行               |
| core-image-full-cmdline | 全功能命令行             |
| core-image-sato         | gui 模式                 |
| core-image-weston       | 基于 wayland 的 gui      |
| meta-toolchain          | 工具链                   |
| meta-ide-support        | ide 支持，主要是 eclipse |

## 独立编译

在 `build/conf/bblayers.conf` 里面，指定的所有的 layers 目录里面

如果有 `xxx_0.1.bb`，就可以独立编译

```sh
bitbake xxx
```

## 清理

```sh
bitbake xxx -c clean
```

| 命令        | 删除                                                  | 保留                |
| ----------- | ----------------------------------------------------- | ------------------- |
| clean       | 构建产物                                              | sstate 缓存和源码包 |
| cleansstate | 构建产物和 sstate 缓存，清理 recipe 的缓存            | 源码包              |
| cleanall    | 构建产物，sstate 缓存，清理 recipe 及其所有依赖的缓存 | 源码包              |

## 遇到错误

忽略遇到的错误，继续进行

```sh
bitbake xxx --continue
```

## 下载太慢

手动下载

```sh
git clone --branch v6.12/standard/base https://git.yoctoproject.org/linux-yocto.git git.yoctoproject.org.linux-yocto.git --depth=1

# 手动挪到 build/downloads/git2/ 下
# 创建 done 文件
touch git.yoctoproject.org.linux-yocto.git.done
```

## 运行

bitbake 结束以后，运行虚拟机

```sh
runqemu qemux86-64
```
