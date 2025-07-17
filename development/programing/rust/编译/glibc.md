# glibc

## 场景

cdylib 和 dylib 类型的项目不能静态编译，因此，考虑降低需要的 glibc 的版本

## 步骤

[cargo-zigbuild](https://github.com/rust-cross/cargo-zigbuild)

支持动态库和 exe

```sh
cargo install cargo-zigbuild
```

查看目标 glibc 版本

```sh
ldd --version
```

项目编译

```sh
cargo zigbuild --release --target x86_64-unknown-linux-gnu.2.31
```
