# ssh 操作

主要是 ct_ssh 模块

不需要自己配置.ssh 目录

## 步骤

sshdemo.config

```erlang
{sshdemo,
  [
    {ssh, "127.0.0.1"},
    {port, 22},
    {user, "yourname"},
    {password, "yourpassword"}
  ]
}.
```

### 启动

erlang 的 vm 里面的 shell 启动

```erlang
ct:install([{config,"/home/xxx/downloads/demo/sshdemo.config"}]).
ct:start_interactive().
```

单命令启动

```erlang
ct_run -shell -logdir /tmp/ -config sshdemo.config
```

### 检查配置文件是否正确

```erlang
ct:get_config(sshdemo).
```

### 文件读写

```erlang
{ok, CH}=ct_ssh:connect(sshdemo, sftp).
ct_ssh:make_dir(CH, "/tmp/sshdemo").
ct_ssh:list_dir(CH, "/tmp/sshdemo").
ct_ssh:write_file(CH, "/tmp/sshdemo/test.dat", "hello").
ct_ssh:read_file(CH, "/tmp/sshdemo/test.dat").
```

### 命令操作

```erlang
{ok, CH1}=ct_ssh:connect(sshdemo, ssh).
ct_ssh:exec(CH1, "cp /tmp/sshdemo/test.dat /tmp/sshdemo/test1.dat").
```

### 启动远程节点

```erlang
ct_run -shell -logdir /tmp/ -name x@127.0.0.1
ct_slave:start('127.0.0.1', 'y@127.0.0.1', [{username, "yourname"},{password, "yourpassword"}]).
```
