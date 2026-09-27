# rclone

## 说明

目标机器不需要装

```sh
SRC 无论加不加 /, 操作的都是 SRC 这个目录
```

## 用法

### 参数说明

```sh
--transfers               小文件多，加大
--metadata                保留权限
--delete-during           边传边删除
--create-empty-src-dirs   保留空目录
```

### 目录

同步目录，不一样的删除

```sh
rclone sync \
  --progress --metadata --delete-during --create-empty-src-dirs \
  $LOCAL_DIR ":sftp,host=$REMOTE_IP,user=$REMOTE_USER:$REMOTE_DIR"
```

### 文件

```sh
# 保存的文件名无法指定
rclone copy --progress --include "*.tar.gz" :sftp,host=xx.xx.xx.xx,user=root:/tmp ~/downloads/
```

```sh
# 指定文件名
rclone copyto --progress :sftp,host=xx.xx.xx.xx,user=root:/tmp/aaa.tar.gz ~/downloads/111.tar.gz
```

### 网盘

```sh
rclone mount --vfs-cache-mode full --sftp-ask-password :sftp,host=xx.xx.xx.xx,user=root:/tmp ~/downloads/aaaaaaa
```
