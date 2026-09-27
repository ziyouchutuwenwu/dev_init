# zig

## 说明

exe 类型，可以静态编译

动态库不支持静态编译，只能降低依赖的 glibc 版本

## 安装

[cargo-zigbuild](https://github.com/rust-cross/cargo-zigbuild)

```sh
cargo install cargo-zigbuild
```

## 用法

### exe

可以静态编译

```sh
cargo zigbuild --release --target x86_64-unknown-linux-musl
```

### 动态库

指定 glibc 最高版为 2.31

```sh
cargo zigbuild --release --target x86_64-unknown-linux-gnu.2.31
```

测试

```sh
# 查看当前
ldd --version

# 查看动态库的 glibc
objdump -p xxx.so | rg GLIBC_
```
