# smb

## 用法

### linux

```sh
mount.cifs -o username=xxx,password=xxx,iocharset=utf8 //192.168.1.11/smb /mnt/smb
```

### freebsd

```sh
/etc/hosts
```

```txt
# 这里必须和真实 smb 服务器保持对应，否则连接失败
192.168.88.41 win10
```

不能使用 ip，必须使用 netbios 名

```sh
mount_smbfs //mmc@win10/smb /opt/smb
```
