# rpc

## 说明

默认 rpc 的时候，会自动连接节点

### 自动连接

```sh
erl -name aaa@127.0.0.1 -setcookie 123456
```

```erlang
rpc:call('debug@127.0.0.1', demo, start, []).
```

### 手动连接

是用来设置当前节点不去主动连接其它节点，其它节点还是可以主动连接过来的

```sh
erl -name aaa@127.0.0.1 -setcookie 123456 -kernel dist_auto_connect never
```

rebar3 项目, release 的 sys.config

```erlang
[
  {kernel,
  [
    {dist_auto_connect, never}
  ]}
].
```

```erlang
net_kernel:connect_node('debug@127.0.0.1').
rpc:call('debug@127.0.0.1', demo, start, []).
```
