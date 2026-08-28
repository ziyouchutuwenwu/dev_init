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

## 测试

```sh
cargo new demo
```

build.rs

```rust
use std::fs;

fn link_dylib(so_path: &str) {
    let so_dir = fs::canonicalize(so_path).expect("so file not found");
    let src_dir = so_dir.parent().unwrap();
    let so_file = so_dir.file_name().unwrap().to_str().unwrap();

    println!("cargo:rustc-link-search={}", src_dir.display());
    println!("cargo:rustc-link-arg=-l:{so_file}");
    println!("cargo:rustc-link-arg=-Wl,-rpath,$ORIGIN/libs");
}

fn main() {
    link_dylib("../xxx.so");
}
```

main.rs

```rust
unsafe extern "C" {
    fn add(a: i32, b: i32) -> i32;
}

fn main() {
    let a = 10;
    let b = 20;
    let sum = unsafe { add(a, b) };
    println!("{a} + {b} = {sum}");
}
```
