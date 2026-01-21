# proplist

## 用法

```erlang
Proplist1 = [ {key1, value1}, {key2, value2}, {key3, value3} ].
Value = proplists:get_value(key2, Proplist1).
HasKey = proplists:is_defined(key2, Proplist1).
```
