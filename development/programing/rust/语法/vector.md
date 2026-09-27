# vector

## 例子

```rust
#[derive(Debug)]
struct Person {
    name: String,
    age: u32,
}
fn main() {
    let mut people_vector = Vec::new();
    let person1 = Person {
        name: String::from("Alice"),
        age: 30,
    };
    let person2 = Person {
        name: String::from("Bob"),
        age: 25,
    };
    people_vector.push(person1);
    people_vector.push(person2);

    for person in &people_vector {
        println!("姓名: {}, 年龄: {}", person.name, person.age);
    }
}
```
