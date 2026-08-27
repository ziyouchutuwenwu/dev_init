# match

## 说明

代替逻辑上的 switch

## 例子

```rust
fn main() {
    let number = 5;

    match number {
        1 => println!("是一"),
        2 => println!("是二"),
        other => println!("值为 {}", other),
    }
}
```
