# cc-switch

## 说明

多种 cli 的配置各不相同，mcp 和 skill 的管理也是完全不同

[这个](https://github.com/SaladDay/cc-switch-cli) 可以集中管理

## 配置

### provider

默认 app 是 claude

添加

```sh
cc-switch --app codex provider add
```

查看

```sh
cc-switch --app codex provider list
```

使用某个

```sh
cc-switch --app codex use id_xxx
cc-switch --app codex provider switch id_xxx
```

### 代理

查看

```sh
cc-switch proxy show
```

修改端口

```sh
cc-switch --app claude proxy config --listen-port 15721
cc-switch --app codex proxy config --listen-port 15722
```

生效，同步到 cli 的配置文件

```sh
cc-switch --app codex proxy enable
```

### 提示词

```sh
cc-switch --app codex prompts list
cc-switch --app codex prompts create
cc-switch --app codex prompts edit
cc-switch --app codex prompts rename
cc-switch --app codex prompts delete
cc-switch --app codex prompts activate
cc-switch --app codex prompts deactivate
```

### mcp

同步

```sh
cc-switch --app codex mcp sync
```

查看

```sh
cc-switch --app codex mcp list
```

### skill

同步

```sh
cc-switch --app codex skills sync
```

### 启动

```sh
cc-switch daemon start --detach
cc-switch daemon stop
```

### config

查看

```sh
cc-switch --app codex config show
```

导出的是 sql

```sh
cc-switch --app codex config export ./bak.sql
cc-switch --app codex config import ./bak.sql
```
