# rpc 调用

## 步骤

### 集群互相联通

### rpc

```erlang
rpc:call(node, module, fun, args)
```

```erlang
rpc:call('bbb@manjaro', 'Elixir.Example', sum, [2,3]).
```

```elixir
:rpc.call(:aaa@manjaro, :erlang, :now, [])
```
