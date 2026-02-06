# mount

## 启动挂载磁盘

## 注意

重启之前，一定要做好测试，fstab 出现错误会开不了机

## 步骤

### 查看磁盘

```sh
fdisk -l
```

### 格式化

```sh
mkfs.ext4 /dev/vdb
```

### 手动挂载测试

```sh
mkdir -p /tmp/aaa
mount /dev/vdb /tmp/aaa
rm -rf /tmp/aaa
```

### 查看挂载点

```sh
df -T
findmnt --df
findmnt -t ext4
```

### 自动挂载

/etc/fstab

```sh
/dev/vdb /mnt/vdb ntfs defaults 0 0
```

重启之前一定要测试

```sh
mount -a
```
