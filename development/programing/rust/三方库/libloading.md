# libloading

## 说明

加载动态库，跨平台

## 用法

```sh
cargo new demo
```

```sh
cargo add libloading
```

main.rs

```rust
use libloading::{Library, Symbol};

fn main() -> Result<(), Box<dyn std::error::Error>> {
    unsafe {
        let lib = Library::new("./libdemo_lib.so")?;
        let add: Symbol<unsafe extern "C" fn(u64, u64) -> u64> = lib.get(b"add")?;

        let result = add(2, 3);
        println!("2 + 3 = {}", result);
    }
    Ok(())
}
```
