# 调用 crate

## 例子

### crate

```sh
cargo new demo_lib --lib
```

目录结构

```sh
.
├── Cargo.lock
├── Cargo.toml
└── src
    ├── aaa
    │   ├── demo1.rs
    │   └── mod.rs
    └── lib.rs
```

文件

`src/lib.rs`

```rust
pub mod aaa;
```

`src/aaa/mod.rs`

```rust
pub mod demo1;
```

`src/aaa/demo1.rs`

```rust
pub fn hi(left: usize, right: usize) -> usize {
left + right
}
```

### 调用方

Cargo.toml

```toml
[dependencies]
demo_lib = { path = "../demo_lib" }
```

src/main.rs

```rust
extern crate demo_lib;

fn main() {
    let a = demo_lib::aaa::demo1::hi(22,33);
    println!("result is {}", a);
}
```
