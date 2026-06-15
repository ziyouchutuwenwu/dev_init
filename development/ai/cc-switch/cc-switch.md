# cc-switch

## 说明

多种 cli 的配置各不相同，mcp 和 skill 的管理也是完全不同

[这个](https://github.com/SaladDay/cc-switch-cli) 可以集中管理

## 配置

给 codex 添加 provider

```sh
cc-switch --app codex provider add
```

cc-switch 的配置同步到 codex

```sh
cc-switch proxy enable --app codex
```

同步 mcp

```sh
cc-switch --app codex mcp sync
```

查看 mcp

```sh
cc-switch --app codex mcp list
```

同步 skills

```sh
cc-switch --app codex skills sync
```
