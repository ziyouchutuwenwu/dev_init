# result

## 说明

带有 OK 和 Err 数据容器

## 例子

```rust
fn main() {
    let aaa: Result<i32, &str> = Ok(100);
    match aaa {
        Ok(val) => println!("成功拿到了：{}", val),
        Err(_) => {}
    }

    let bbb: Result<i32, &str> = Err("没钱了");
    match bbb {
        Err(err) => println!("失败原因：{}", err),
        Ok(_) => {}
    }
}

```
