# freebsd

中科大镜像下载 iso

## 配置

参考 [这里](http://www.chinafreebsd.cn/article/chinafreebsd-resouce)

### pkg 源

```sh
mkdir -p /usr/local/etc/pkg/repos/
vi /usr/local/etc/pkg/repos/FreeBSD.conf
```

latest 表示滚动更新的版本库，想要稳定些版本换成 quarterly

```bash
FreeBSD: {
    url: "pkg+http://mirrors.ustc.edu.cn/freebsd-pkg/${ABI}/latest"
}
```

更新索引

```sh
pkg update -f
pkg install -y vim axel
```

### port 源

需要先安装 axel

在 /etc/make.conf 中添加以下内容

```sh
FETCH_CMD=axel -n 10 -a
DISABLE_SIZE=yes
MASTER_SITE_OVERRIDE?=http://mirrors.ustc.edu.cn/freebsd-ports/distfiles/${DIST_SUBDIR}/
```

### portsnap

vi /etc/portsnap.conf

```sh
SERVERNAME=portsnap.FreeBSD.org
修改为
SERVERNAME=portsnap.hshh.org
```

portsnap fetch extract

### freebsd-update 源

vi /etc/freebsd-update.conf

```sh
ServerName 后面的字段
修改为
update.freebsd.cn
```

使用如下的命令下载(同版本内子版本升级)

```sh
freebsd-update fetch
```

安装

```sh
freebsd-update install
```
