# syn

## 说明

类似 elixir 的 horde 库

## 用法

app.src 里面

```erlang
{applications, [
  ...
  syn
]}
```

启动

```sh
rebar3 shell --name aaa@127.0.0.1 --setcookie 123456
rebar3 shell --name bbb@127.0.0.1 --setcookie 123456
```

连通

```erlang
net_kernel:connect_node('aaa@127.0.0.1').
nodes().
```

测试

```erlang
syn:add_node_to_scopes([users]).
Pid = self().
syn:register(users, "aaa", Pid).
syn:lookup(users, "aaa").
syn:register(users, "bbb", Pid, [{xxx, "zzz"}]).
syn:lookup(users, "bbb").
syn:registry_count(users).
```

```erlang
syn:add_node_to_scopes([users]).
Pid = self().
% 对于 user 这个 scope 下面的某个组
syn:join(users, {xxx, yyy}, Pid).
syn:members(users, {xxx, yyy}).
syn:is_member(users, {xxx, yyy}, Pid).
syn:publish(users, {xxx, yyy}, "custom msg").
flush().
```
