# enum

## 说明

支持不同类型，比较的时候，类似模式匹配

## 例子

```rust
enum Book {
    Papery(u32),
    Electronic { url: String },
}

fn main() {
    let book = Book::Papery(1001);

    match book {
        Book::Papery(i) => {
            println!("{}", i);
        }
        Book::Electronic { url } => {
            println!("{}", url);
        }
    }
}
```

## 对 None 的处理

用于确保准确的处理空值

```rust
fn main() {
    let opt = Option::Some("Hello");
    match opt {
        Option::Some(something) => {
            println!("{}", something);
        },
        Option::None => {
            println!("opt is nothing");
        }
    }
}
```
