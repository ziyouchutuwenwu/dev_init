# tmpfs

内存文件系统, 可以通过 `df -h` 查看

## 用法

### 手动挂载

```sh
mount demo -t tmpfs -o size=2G -o mode=1777 /tmp
```

### 开机挂载

/etc/fstab

```sh
demo /tmp tmpfs defaults,noatime,mode=1777,size=2G 0 0
```

### 动态扩容

比如 manjaro

```sh
mount tmpfs -t tmpfs -o size=4G -o remount /tmp
```
