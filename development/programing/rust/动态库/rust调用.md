# rust 调用

## 说明

其它 rust 程序调用这个动态库

## 步骤

创建项目

```sh
cargo new demo_so --lib
```

Cargo.toml

```toml
[lib]
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
demo_so = { path = "../demo_so" }
```

main.rs

```rust
fn main() {
    let result = demo_so::add(2, 3);
    println!("2 + 3 = {}", result);
}
```
