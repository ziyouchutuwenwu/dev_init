# super

## 说明

super 相当于从父模块中引用

```rust
use super::bbb;
```

表明从当前模块的父模块中引入 bbb

## 例子

结构如下

```sh
src
├── main.rs
└── sub
    ├── aaa.rs
    ├── bbb.rs
    └── mod.rs
```

内容

mod.rs

```rust
pub mod aaa;
pub mod bbb;
```

aaa.rs

```rust
use super::bbb;

pub fn demo(){
  println!("demo in aaa");
}

pub fn aaa(){
  bbb::demo();
}
```

bbb.rs

```rust
use super::aaa;

pub fn demo(){
  println!("demo in bbb");
}

pub fn bbb(){
  aaa::demo();
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
