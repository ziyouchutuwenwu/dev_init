# cdylib

## 说明

cdylib 别的语言都可以调用

## 例子

创建项目

```sh
cargo new demo_lib --lib
```

Cargo.toml

```toml
[lib]
crate-type = ["cdylib"]
```

lib.rs

```rust
// no_mangle 不修改导出的函数名
#[unsafe(no_mangle)]
pub extern "C" fn add(left: u64, right: u64) -> u64 {
    left + right
}
```
