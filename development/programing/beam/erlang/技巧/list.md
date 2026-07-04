# list

## 用法

### 显示原始 list

当我们在 shell 里面得到的结果是 List，shell 会尝试把结果变成 a printable string，比如

```erlang
1> [65,66,67,68,69].
"ABCDE"
```

关闭方式

```erlang
shell:strings(false).
```

### list 追加

list 做 ++ 或者 append 的时候，小列表在左边

### 判断非空

```erlang
case List of
    [_|_] -> do_not_empty_work(List);
    _ -> do_empty_work()
end
```
