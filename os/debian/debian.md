# debian

## 说明

网络配好以后，断网安装，否则会去找 security 源，非常慢

ssh 服务要装

## 调试

### 打印 log

xfce 终端设置

```sh
通用 ->
  取消 -> 输出时滚动
  选择 -> 无限回滚
```

结果中搜索 `E:` 即可看到错误的问题

### 暂停脚本

```python
input("暂停的信息")
```

## 注意

### 脚本运行前

开启 sshd 的 root 登录，然后 scp 过去执行

```sh
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
systemctl restart sshd
```

创建 python 的 link

```sh
ln -s /usr/bin/python3 /usr/bin/python
```

### 设置代理

带桌面的话，不要用 `HTTP_PROXY` 和 `HTTPS_PROXY`

配置非 root 用户的 git 代理

```sh
~/.gitconfig
```

```sh
[http]
  proxy = socks5://127.0.0.1:1080
[https]
  proxy = socks5://127.0.0.1:1080
```

配置非 root 用户的 curl 代理

```sh
~/.curlrc
```

```sh
proxy=socks5://127.0.0.1:1080
```

### 脚本运行后

桌面右上角设置

```sh
时间 -> 右键 -> 属性
  外观 -> 布局 -> 数字式
  时钟选项 -> 布局 -> 仅时间
  时间 -> 格式 -> 自定义格式 -> %Y-%m-%d %H:%M:%S
```

xfce 终端设置

```sh
外观 ->
  字体 -> Monaco 11
  默认几何属性 -> 100 22
```

### lightdm

用户头像

```sh
/usr/share/icons/Faenza/devices/scalable/display.png
```
