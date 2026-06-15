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
cc-switch --app codex use xxx
```

切换

```sh
cc-switch --app codex provider switch xxx
```

### 代理

查看

```sh
cc-switch proxy show
```

codex 需要转发

```sh
# cc-switch 能把一些非标格式的转换为标准格式
cc-switch --app codex proxy enable
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
cc-switch daemon start
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
