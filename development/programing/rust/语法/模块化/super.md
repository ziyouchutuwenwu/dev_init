# super

## 说明

类似于 `import "../xxx"`，但跨的是 module

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

mod.rs

```rust
pub mod aaa;
pub mod bbb;
```

aaa.rs

```rust
use super::bbb;

pub fn demo(){
  println!("in aaa");
}

pub fn aaa(){
  bbb::demo();
}
```

bbb.rs

```rust
use super::aaa;

pub fn demo(){
  println!("in bbb");
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
