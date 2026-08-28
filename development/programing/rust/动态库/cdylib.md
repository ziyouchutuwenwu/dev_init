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
use std::env;

fn link_dylib(so_path: &str) {
    let so_dir = fs::canonicalize(so_path).expect("so file not found");
    let src_dir = so_dir.parent().unwrap();
    let so_file = so_dir.file_name().unwrap().to_str().unwrap();

    println!("cargo:rustc-link-search={}", src_dir.display());
    println!("cargo:rustc-link-arg=-l:{so_file}");
    println!("cargo:rustc-link-arg=-Wl,-rpath,$ORIGIN/libs");
}

fn main() {
    // TARGET 不需要手动设置，cargo build --target=xxx 的时候，会自动设置
    let target = env::var("TARGET").unwrap_or_default();

    if target.contains("aarch64") {
        link_dylib("../c_lib/build/xxx.so");
    } else {
        link_dylib("../clib_pc/build/xxx.so");
    }
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
