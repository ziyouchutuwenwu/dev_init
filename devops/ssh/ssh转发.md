# ssh 转发

## 注意

sshd 出来的服务能给别人访问

```sh
/etc/ssh/sshd_config
GatewayPorts yes
```

## 代理服务器

把本地 1080 的流量转发给 VPS, socks5 代理模式

```sh
ssh -vv -o "StrictHostKeyChecking no" -CfND 0.0.0.0:1080 $VPS_USER@$VPS_IP
```

## 本地转发

把远程服务变为本地服务

LOCAL_IP 不要用 0.0.0.0, 否则访问不了

REMOTE_IP 和 VPS_IP 可以不相同

开启 gateway 模式

```sh
ssh -vv -o "StrictHostKeyChecking no" -CfNg -L $LOCAL_IP:$LOCAL_PORT:$REMOTE_IP:$REMOTE_PORT $VPS_USER@$VPS_IP
```

## 远程转发

把服务转发给其它机器

开启 gateway 模式

```sh
ssh -vv -o "StrictHostKeyChecking no" -CfNg -R $NEW_SERVER_PORT:$OLD_SERVER_IP:$OLD_SERVER_PORT $NEW_SERVER_USER@$NEW_SERVER_IP
```
