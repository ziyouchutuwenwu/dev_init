# garray 用法

## 贴一些重要的用法

### replace

```golang
func ReplaceAt(array *garray.Array, index int, value interface{}) {
  array.Remove(index)
  err := array.InsertBefore(index, value)
  if err != nil {
    array.Append(value)
  }
}
```

### remove

`index -1` 以后，不要对 array 做其它操作

```golang
array.RemoveValue(value)
index -= 1
```
