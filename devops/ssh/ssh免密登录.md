# ssh 免密登录

## 客户端配置

### 生成公钥

```sh
ssh-keygen -t rsa -b 4096 -C "xxx@xxx.com"
```

对于多套密钥的话，最好指定密钥文件名

```sh
ssh-keygen -t rsa -b 4096 -C "xxx@xxx.com" -f ~/downloads/key_file_name
```

### 注意

```sh
.ssh 文件夹必须是700
.ssh 文件夹下面的文件权限必须是600
```

```sh
chmod 700 ~/.ssh
chmod 600 ~/.ssh/*
```

### 上传公钥

公钥上传以后，路径为 `~/.ssh/authorized_keys`, 登陆只需要用私钥

```sh
ssh-copy-id -i ~/.ssh/id_rsa.pub root@192.168.56.11
```

## 连接

可以把公钥和私钥另外保存

```sh
# 指定key
ssh -i ~/.ssh/id_rsa root@192.168.56.11
```

## ssh 服务端

可以不配置

`vim /etc/ssh/sshd_config`

```sh
# 禁用密码验证
PasswordAuthentication no

# 启用密钥验证
RSAAuthentication yes
PubkeyAuthentication yes

# 指定公钥数据库文件
AuthorizedKeysFile .ssh/authorized_keys
```
