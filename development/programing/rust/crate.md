# crate

## 例子

### lib 方

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

lib.rs

```rust
pub mod aaa;
```

aaa/mod.rs

```rust
pub mod demo1;
```

aaa/demo1.rs

```rust
pub fn demo(left: usize, right: usize) -> usize {
    left + right
}
```

### 调用方

Cargo.toml

```toml
[dependencies]
demo_lib = { path = "../demo_lib" }
```

main.rs

```rust
extern crate demo_lib;

fn main() {
    let a = demo_lib::aaa::demo1::demo(22, 33);
    println!("result is {}", a);
}
```
