# rpc

## 用法

```erlang
rpc:call(node, module, fun, args)
```

```erlang
rpc:call('bbb@manjaro', 'Elixir.Example', sum, [2,3]).
```

```elixir
:rpc.call(:aaa@manjaro, :erlang, :now, [])
```
