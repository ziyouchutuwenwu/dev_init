# rsync

## 用法

### 基础用法

```sh
rsync $SRC $DEST
```

### 本机备份到远程

```sh
rsync -azvh --partial --progress --delete $LOCAL_DIR $REMOTE_USER@$REMOTE_IP:$REMOTE_DIR
```

### 远程备份到本机

```sh
rsync -azvh --partial --progress --delete $REMOTE_USER@$REMOTE_IP:$REMOTE_DIR $LOCAL_DIR
```

### 只显示不传输

类似下面

```sh
rsync --dry-run xxx
```
