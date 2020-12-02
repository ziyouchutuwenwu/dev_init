# vscode 断点调试 php

## 安装 xdebug 插件

## docker 配置

- xdebug 配置

```text
xdebug.remote_enable=on
xdebug.remote_autostart=on
xdebug.remote_connect_back=on
```

- 容器里的 9000 端口不需要暴露出来
- 测试容器

```sh
docker run --rm -d -name apache_php -p 8888:80 -v ~/projects/docker/web_root:/app -e XDEBUG_REMOTE_AUTOSTART=1 -e XDEBUG_REMOTE_ENABLE=1 webdevops/php-apache-dev:7.3
```

## vscode 的调试配置里面，一定要有这个

```json
"pathMappings": {
    "/app": "${workspaceRoot}"
}
```
