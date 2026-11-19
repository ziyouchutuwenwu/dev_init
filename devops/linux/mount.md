# mount

## 说明

fstab 出现错误, 默认会开不了机

加上 nofail，重启之前测试

## 步骤

查看磁盘

```sh
fdisk -l
```

格式化

```sh
mkfs.ext4 /dev/vdb
```

### 手动挂载

```sh
mkdir -p /tmp/aaa
mount /dev/vdb /tmp/aaa
rm -rf /tmp/aaa
```

查看挂载点

```sh
df -T
findmnt --df
findmnt -t ext4
```

### 启动挂载

用 uuid

```sh
blkid /dev/vdb
```

/etc/fstab

```sh
#/dev/vdb /mnt/vdb ext4 defaults,nofail 0 0
UUID=xxxx-xxxx /mnt/vdb ext4 defaults,nofail 0 0
```

重启之前测试

```sh
mount -a
```
