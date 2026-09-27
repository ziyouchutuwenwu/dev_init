# import

## 说明

不需要写模块名，直接写方法

## 例子

### 导入全部

```elixir
import List

first([1,2,3])
last([1,2,3])
```

### 导入部分函数

只导入 `last/1` 和 `first/1` 这两个函数

```elixir
import List, only: [last: 1, first: 1]

first([1,2,3])
last([1,2,3])
```

### 导入除掉 xxx 之外的函数

导入除 `last/1` 之外的其他所有函数

```elixir
import List, except: [last: 1]

first([1,2,3])
last([1,2,3])
```

### 只导入函数或宏

通过 :only 和 :except 来过滤导入当前模块的函数和宏

```elixir
import List, only: :functions
import List, only: :macros
```
