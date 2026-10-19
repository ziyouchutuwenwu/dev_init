# default

## 说明

就是默认实现

## 例子

```rust
#[derive(Debug)]
struct Demo {
    port: u16,
    timeout: u32,
}

impl Default for Demo {
    fn default() -> Self {
        Demo {
            port: 8080,
            timeout: 30,
        }
    }
}

fn main() {
    let demo = Demo::default();
    println!("port: {}, timeout: {}", demo.port, demo.timeout);
}
```
