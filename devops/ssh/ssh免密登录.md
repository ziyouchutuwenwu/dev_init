# ssh 免密登录

## 说明

普通用户做对于 root 的本机免密登录，不需要切换到 root 再做，当前用户下也可以直接做

## 客户端配置

### 生成公钥

最好指定密钥文件名，默认是在 ~/.ssh 下面

```sh
ssh-keygen -t rsa -b 4096 -C "xxx@xxx.com" -f ~/downloads/key
```

### 注意

私钥权限必须是 600

```sh
chmod 600 ~/downloads/*
```

如果是在 ~/.ssh 下生成的密钥

```sh
chmod 600 ~/.ssh/*
```

### 上传公钥

上传本地公钥

```sh
ssh-copy-id -i ~/downloads/key.pub root@192.168.56.11
```

### 私钥连接

```sh
ssh -i ~/downloads/key root@192.168.56.11
```

## ssh 服务端

可以不配置

```sh
/etc/ssh/sshd_config
```

禁用密码验证

```sh
PasswordAuthentication no
```

启用密钥验证

```sh
RSAAuthentication yes
PubkeyAuthentication yes
```

上传的公钥数据库保存的路径

```sh
# 这是默认位置
AuthorizedKeysFile .ssh/authorized_keys
```
