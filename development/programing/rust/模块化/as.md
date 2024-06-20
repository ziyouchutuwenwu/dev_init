# as

## 例子

起个别名，简化输入

```rust
extern crate demo_lib;

use demo_lib::sub_dir::sub1::mod2::mod3 as ppp;

fn main() {
    ppp::f2();
}
```
