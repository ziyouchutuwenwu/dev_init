# musl

## 说明

无依赖的静态编译

cdylib 和 dylib 类型的项目不支持

## 步骤

### toolchain

```sh
rustup target list | grep musl
rustup target add x86_64-unknown-linux-musl
rustup target remove xxx
```

### 编译配置

```sh
.cargo/config.toml
```

```sh
[build]
target = "x86_64-unknown-linux-musl"
# 多个
# target = ["x86_64-unknown-linux-gnu", "x86_64-unknown-linux-musl"]
```

编译

```sh
cargo build --release
```

或者

```sh
cargo build --release --target=x86_64-unknown-linux-musl
```
