# thread

## 例子

```rust
use std::thread;
use std::time::Duration;

fn main() {
    let data = vec![1, 2, 3];
    thread::scope(|thread| {
        thread.spawn(|| {
            println!("子线程 1 正在干净地运行，还能直接借用数据: {:?}", data);
        });

        thread.spawn(|| {
            thread::sleep(Duration::from_millis(10));
            println!("子线程 2 正在默默运行...");
        });

        println!("主线程在干活...");
    });

    println!("所有线程都已在上面自动 join 完成，这里可以安全继续。");
}
```
