# vscode 断点调试 php

## 安装 xdebug 插件

## docker 里面的 xdebug 配置

```text
xdebug.remote_enable=on
xdebug.remote_autostart=on
xdebug.remote_connect_back=on
```

## vscode 的调试配置里面，一定要有这个

```json
"pathMappings": {
    "/app": "${workspaceRoot}"
}
```
