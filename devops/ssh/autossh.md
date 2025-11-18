# autossh

## 用法

### 本地隧道

原来需要远程访问的服务，变为本地访问的服务

TARGET_IP 和 VPS_IP 可以不相同

```sh
autossh -M 0 -i ./keys/id_rsa \
  -o "StrictHostKeyChecking no" \
  -o "ServerAliveInterval 30" \
  -CfNg -L $LOCAL_IP:$LOCAL_PORT:$TARGET_IP:$TARGET_PORT \
  root@$VPS
```

### 远程隧道

把服务转发给其它机器

```sh
autossh -M 0 -i ./keys/id_rsa \
  -o "StrictHostKeyChecking no" \
  -o "ServerAliveInterval 30" \
  -CfNg -R $NEW_SERVER_PORT:$OLD_SERVER_IP:$OLD_SERVER_PORT \
  root@$NEW_SERVER_IP
```
