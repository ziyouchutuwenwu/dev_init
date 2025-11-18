# option

## 说明

用于表示一个值可能存在也可能不存在

有两个变体

```sh
Some(T)
None
```

## 例子

```rust
fn divide(a: i32, b: i32) -> Option<i32> {
    if b == 0 {
        None
    } else {
        Some(a / b)
    }
}

fn main() {
    let result1 = divide(10, 2);
    match result1 {
        Some(value) => println!("Result: {}", value),
        None => println!("Cannot divide by zero."),
    }

    let result2 = divide(10, 0);
    match result2 {
        Some(value) => println!("Result: {}", value),
        None => println!("Cannot divide by zero."),
    }
}
```
