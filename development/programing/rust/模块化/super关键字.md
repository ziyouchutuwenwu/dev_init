# super关键字

使用 super 关键字作为相对路径的模块调用

## 例子

结构如下

```sh
├── Cargo.toml
└── src
    ├── main.rs
    └── sub
        ├── aaa.rs
        ├── bbb.rs
        └── mod.rs
```

内容

mod.rs

```rust
// 文件名
pub mod aaa;
pub mod bbb;
```

aaa.rs

```rust
use super::bbb;

pub fn demo1(){
  println!("demo1");
}

pub fn aaa(){
  bbb::demo2();
}
```

bbb.rs

```rust
use super::aaa;

pub fn demo2(){
  println!("demo2");
}

pub fn bbb(){
  aaa::demo1();
}
```

main.rs

```rust
mod sub;
use sub::aaa;
use sub::bbb;

fn main() {
    aaa::aaa();
    bbb::bbb();
}
```
