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

# 清理
bitbake -c cleanall xxx
```
