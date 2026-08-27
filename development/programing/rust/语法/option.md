# option

## 说明

带有 Some 和 None 数据容器

## 例子

```rust
fn main() {
    // None
    let money: Option<i32> = Some(100);

    match money {
        Some(val) => println!("有钱：{}", val),
        None => println!("没钱"),
    }
}
```
