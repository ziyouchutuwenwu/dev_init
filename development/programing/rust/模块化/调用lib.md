# 调用 lib

相对路径调用库的例子

## 步骤

### lib

```sh
cargo new demo_lib --lib
```

结构见 [文件作为模块.md](./文件作为模块.md)

`lib.rs`

```rust
pub mod sub_dir;
pub mod mod1;
```

### bin

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
extern crate demo_lib;

use demo_lib::mod1;
use demo_lib::sub_dir::sub1::mod2::mod3;

fn main() {
    mod1::f1();
    mod3::f2();
}
```
