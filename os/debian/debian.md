# 说明

## 步骤

### 休眠配置

[配置参考这里](https://wiki.debian.org/Suspend)，脚本已内置，实时生效，不需要重启。

测试命令

```sh
systemctl suspend
systemctl hibernate
```

### 准备工作

选择 expert 模式，去掉 security 包，不然非常慢

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

带桌面的话，配置非 root 用户的 git 和 curl 的代理

不要用 `http_proxy` 和 `https_proxy`

### 脚本结束

桌面右上角设置

```sh
时间 -> 右键 -> 属性
  外观 -> 布局 -> 数字式
  时钟选项 -> 布局 -> 仅时间
  时间 -> 格式 -> 自定义格式 -> %Y-%m-%d %H:%M:%S
```

### 调试

#### 打开调试

xfce 终端设置

```sh
取消 输出时滚动
选择 无限回滚
```

结果中搜索 `E:` 即可看到错误的问题

#### 暂停脚本

```python
input("暂停的信息")
```
