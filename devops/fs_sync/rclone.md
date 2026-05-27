# rclone

## 说明

目标机器不需要装

```sh
SRC 无论加不加 /, 操作的都是 SRC 这个目录
小文件多，加大 transfers
```

## 用法

### 目录

同步目录，不一样的删除

```sh
rclone sync \
  --transfers=1 --progress --delete-during --create-empty-src-dirs \
  $LOCAL_DIR ":sftp,host=$REMOTE_IP,user=$REMOTE_USER:$REMOTE_DIR"
```

### 文件

```sh
# 保存的文件名无法指定
rclone copy --progress --include "*.tar.gz" :sftp,host=xx.xx.xx.xx,user=root:/tmp ~/downloads/
```

```sh
# 指定文件名
rclone copyto --progress :sftp,host=xx.xx.xx.xx,user=root:/tmp/code-stable-x64-1779186414.tar.gz ~/downloads/111.tar.gz
```

### 网盘

```sh
rclone mount --vfs-cache-mode full :sftp,host=xx.xx.xx.xx,user=root:/tmp ~/downloads/aaaaaaa
```
