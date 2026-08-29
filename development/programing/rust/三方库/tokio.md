# tokio

## 说明

协程库

## 用法

```sh
cargo add tokio --features full
```

task1.rs

```rust
use tokio::sync::mpsc::{Receiver, Sender};

pub async fn run(tx_to_b: Sender<String>, mut rx_from_b: Receiver<String>) {
    println!("task1 发送: Ping");
    tx_to_b.send("Ping".to_string()).await.unwrap();

    let msg = rx_from_b.recv().await.unwrap();
    println!("task1 收到: {}", msg);
}
```

task2.rs

```rust
use tokio::sync::mpsc::{Receiver, Sender};

pub async fn run(tx_to_a: Sender<String>, mut rx_from_a: Receiver<String>) {
    let msg = rx_from_a.recv().await.unwrap();
    println!("task2 收到: {}", msg);

    // 系统调度，让出协程
    tokio::task::spawn_blocking(move || {
        println!(">>> [tokio 托管的原生线程池] 开始执行 CPU 密集型任务...");
        std::thread::sleep(std::time::Duration::from_secs(1));
        println!(">>> [tokio 托管的原生线程池] 计算完成，原消息: {}", msg)
    })
    .await
    .unwrap();

    println!("task2 回复: Pong");
    tx_to_a.send("Pong".to_string()).await.unwrap();
}
```

main.rs

```rust
mod task1;
mod task2;

use tokio::sync::mpsc;

#[tokio::main]
async fn main() {
    let (tx_a_to_b, rx_a_to_b) = mpsc::channel(32);
    let (tx_b_to_a, rx_b_to_a) = mpsc::channel(32);

    let h1 = tokio::spawn(task1::run(tx_a_to_b, rx_b_to_a));
    let h2 = tokio::spawn(task2::run(tx_b_to_a, rx_a_to_b));

    let handles = vec![h1, h2];
    for (i, h) in handles.into_iter().enumerate() {
        match h.await {
            Ok(_) => println!("协程 {} 成功执行完成", i + 1),
            Err(e) => eprintln!("协程 {} 异常崩溃: {}", i + 1, e),
        }
    }
}
```
