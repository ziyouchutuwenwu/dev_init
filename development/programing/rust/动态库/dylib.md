# dylib

## 说明

dylib 只有 rust 才能调用

## 例子

创建项目

```sh
cargo new demo_lib --lib
```

Cargo.toml

```toml
[lib]
# rust 专用的类型
crate-type = ["dylib"]
```

lib.rs

```rust
// 给 rust 程序调用
pub fn add(left: u64, right: u64) -> u64 {
    left + right
}
```

## 测试

```sh
cargo new demo
```

Cargo.toml

```toml
[dependencies]
demo_lib = { path = "../demo_lib" }
```

main.rs

```rust
fn main() {
    let result = demo_lib::add(2, 3);
    println!("2 + 3 = {}", result);
}
```
