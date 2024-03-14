# shell 小技巧

## 查看消息

在当前 shell 内查看消息，调试用

```erlang
flush().
```

## 把 Module 中的 Record 加载到 Shell 中

```erlang
rr(Module).
```

## 把在这个子目录下的所有 Module 里面的 Record 给加载到 Shell 里面

```erlang
rr("*/*").
```

## 类似 netstat 的命令

```erlang
inet:i().
```

## 显示原始 list

当我们在 shell 里面得到的结果是 List，shell 会尝试把结果变成 a printable string，比如

```erlang
1> [65,66,67,68,69].
"ABCDE"
```

关闭方式

```erlang
shell:strings(false).
```

## list ++

list 做++或者 append 的时候，小列表在左边

## 判断非空列表

```erlang
case List of
    [_|_] -> do_not_empty_work(List);
    _ -> do_empty_work()
end
```

## Binary 可以在头或尾任意加数据

```erlang
4> Bin = <<1,2,3>>.
<<1,2,3>>
5> <<Bin/binary,4>>.
<<1,2,3,4>>
```
