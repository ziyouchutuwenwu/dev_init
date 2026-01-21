# hashmap

## 例子

```rust
use std::collections::HashMap;

#[derive(PartialEq, Eq, Hash, Debug)]
struct Point {
    x: i32,
    y: i32,
}

fn main() {
    let mut points_map: HashMap<&Point, i32> = HashMap::new();
    let point1 = Point { x: 1, y: 2 };
    let point2 = Point { x: 3, y: 4 };
    points_map.insert(&point1, 10);
    points_map.insert(&point2, 20);
    if let Some(value) = points_map.get(&point1) {
        println!("点 {:?} 对应的值为: {}", point1, value);
    }
}
```
