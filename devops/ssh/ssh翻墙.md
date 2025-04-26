# ssh 翻墙 sh

## 准备工作

### 免密登陆

按照免密登陆生成密钥

```sh
keys
├── key
└── key.pub
```

### 调试方式

autossh 换成 ssh 可以手动调试

## 脚本

### 本机直连

本机直连远程 vps, 做 socks5 代理

```sh
#! /usr/bin/env /bin/bash

CURRENT_DIR=$(cd "$(dirname "$0")";pwd)

VPS_USER=root
VPS_IP=xx.xx.xx.xx

# 私钥权限一定要是 600
chmod 600 $CURRENT_DIR/keys/*

autossh -i $CURRENT_DIR/keys/key -o "StrictHostKeyChecking no" -o "ServerAliveInterval 30" -o "ServerAliveCountMax 3" -CfND 0.0.0.0:1080 $VPS_USER@$VPS_IP
```

### 跳板机代理

通过跳板机做代理

如果多套密钥，最好在生成的时候指定密钥文件名以区分

只要往跳板机和国外 vps 分别 ssh-copy-id 上传公钥即可

```sh
#! /usr/bin/env /bin/bash

CURRENT_DIR=$(cd "$(dirname "$0")";pwd)

VPS_IP=xx.xx.xx.xx
VPS_SSH_PORT=22

# 跳板机
PROXY_IP=yy.yy.yy.yy

# 私钥权限一定要是 600
chmod 600 $CURRENT_DIR/keys/*

# 跳板机的私钥不需要放在 ~/.ssh/内，通过 -i 参数指定即可
autossh -i $CURRENT_DIR/keys/key -o "StrictHostKeyChecking no" -o "ServerAliveInterval 30" -o "ServerAliveCountMax 3" -CfNg -L 22222:$VPS_IP:$VPS_SSH_PORT root@$PROXY_IP

# 跳板机做免密
# autossh -o "StrictHostKeyChecking no" -o "ServerAliveInterval 30" -o "ServerAliveCountMax 3" -CfNg -L 22222:$VPS_IP:$VPS_SSH_PORT root@$PROXY_IP

sleep 3

# vps 的私钥也是通过路径指定，不需要在跳板机的  ~/.ssh 内指定
autossh -i $CURRENT_DIR/keys/key -o "StrictHostKeyChecking no" -o "ServerAliveInterval 30" -o "ServerAliveCountMax 3" -CfND 0.0.0.0:1080 root@127.0.0.1 -p 22222
```
