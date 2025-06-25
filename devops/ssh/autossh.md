# autossh

## 说明

- 可以自动重联，参数和 ssh 基本一致
- 结合 sshpass 的话，用密码无法自动重连
- 使用密钥，就可以实现自动重联
- 自动重连需要超过 ServerAliveInterval

## 用法

### 基本用法

必须用 key, 不然重连的时候会提示重新输入密码

```sh
autossh -i ./keys/id_rsa \
  -o "StrictHostKeyChecking no" \
  -o "ServerAliveInterval 30" \
  -o "ServerAliveCountMax 3" \
  $VPS_USER@$VPS_IP
```

### 代理服务器

把本地 1080 的流量转发给 VPS, socks5 代理模式

```sh
autossh -i ./keys/id_rsa \
  -o "StrictHostKeyChecking no" \
  -o "ServerAliveInterval 30" \
  -o "ServerAliveCountMax 3" \
  -CfND 0.0.0.0:1080 \
  $VPS_USER@$VPS_IP
```

### 本地隧道

原来需要远程访问的服务，变为本地访问的服务

TARGET_IP 和 VPS_IP 可以不相同

```sh
autossh -i ./keys/id_rsa \
  -o "StrictHostKeyChecking no" \
  -o "ServerAliveInterval 30" \
  -o "ServerAliveCountMax 3" \
  -CfNg -L $LOCAL_IP:$LOCAL_PORT:$TARGET_IP:$TARGET_PORT $VPS_USER@$VPS_IP
```

### 远程隧道

把服务转发给其它机器

```sh
autossh -i ./keys/id_rsa \
  -o "StrictHostKeyChecking no" \
  -o "ServerAliveInterval 30" \
  -o "ServerAliveCountMax 3" \
  -CfNg -R $NEW_SERVER_PORT:$OLD_SERVER_IP:$OLD_SERVER_PORT $VPS_USER@$NEW_SERVER_IP
```
