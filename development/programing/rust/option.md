# option

## 说明

初始化值
作为在整个输入范围没有定义的函数的返回值
如果函数可能有错误，可用 Option<T> 作为返回值，用 None 代表可能出现的错误。
用作 struct 的可选字段
用作函数的可选参数
空指针
用作复杂情况的返回值

## 例子

[参考连接](https://www.jianshu.com/p/ce5bddf4b335)

```rust
struct Student {
    name: String,
    year: u8,
    score: Option<f32>, //可选的字段
}

impl Student {
    fn new(n: String, y: u8) -> Self {
        Self {
            name: n,
            year: y,
            score: None,
        }
    }
    //接收Option作为参数
    fn set_score(&mut self, s: Option<f32>) {
        self.score = s;
    }
}

//返回Option
fn compute_score(s: f32) -> Option<f32> {
    let score = s * 0.75;
    Some(score)
}

fn main() {
    let mut student = Student::new("xiaoming".to_string(), 18);
    dbg!(&student.score);

    let score = compute_score(100.0);
    student.set_score(score);
    dbg!(&student.score);
}
```
