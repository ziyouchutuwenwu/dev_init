# nfs

最关键的是处理权限问题

| 关键字         | 说明                                                       |
| -------------- | ---------------------------------------------------------- |
| root_squash    | 客户端使用 root 访问时，将被映射为匿名用户                 |
| no_root_squash | 客户端使用 root 访问时，服务器上对应的就是 root            |
| all_squash     | 客户端所有用户访问时，都被映射为匿名用户                   |
| no_all_squash  | 客户端所有用户访问时，都会保持其原有的用户身份，这是默认值 |

## 服务端

### linux

#### 安装

服务端

```sh
apt install nfs-kernel-server
```

#### 配置

```sh
/etc/exports
```

```sh
# /mnt/nfs 192.168.56.0/24(rw,insecure,all_squash,no_subtree_check)
# 允许所有 ip
/mnt/nfs *(rw,insecure,all_squash,no_subtree_check)
```

#### 权限

确认提供 nfs 服务的目录权限，主要看 uid 和 gid

```sh
cat /var/lib/nfs/etab
```

核对 uid 和 gid

```sh
cat /etc/passwd | grep nobody
cat /etc/group | grep no
```

配置写权限

```sh
chmod ug+w /mnt/nfs/
chown -R nobody /mnt/nfs/
chgrp -R nogroup /mnt/nfs/
```

#### 生效

重启

```sh
systemctl restart nfs-kernel-server
```

免重启

```sh
exportfs -r
```

### freebsd

[参考地址](https://docs.freebsd.org/zh-cn/books/handbook/network-servers/#network-nfs)

#### rc.conf

```sh
/etc/rc.conf
```

```sh
rpcbind_enable="YES"
nfs_server_enable="YES"
mountd_flags="-r"
```

```sh
/etc/exports
```

```sh
/mnt/nfs
/mounted_demo2
```

#### 查看用户和组

主要看 uid 和 gid

```sh
cat /etc/passwd | grep nobody
cat /etc/group | grep nogroup
```

```sh
chmod ug+w /mnt/nfs/
chown -R nobody /mnt/nfs/
chgrp -R nogroup /mnt/nfs/
```

#### 启动

```sh
service nfsd restart
```

## 客户端

### 检查端口

检查服务器端口

```sh
nc -vz $NFS_SERVER_IP 2049
```

### 挂载远程盘

安装依赖库

```sh
apt install nfs-common
```

挂载

```sh
mount -v -t nfs -o nolock 192.168.56.11:/mnt/nfs ./nfs
```

## 查看挂载

服务器执行

```sh
showmount -e 127.0.0.1
```

客户端执行

```sh
findmnt --df
```

## 权限问题

参考 linux 的权限，服务器和客户端的 gid 一致，客户端操作用户加入到 nogroup 组即可

```sh
cat /etc/group
gpasswd -a $USER nogroup
```
