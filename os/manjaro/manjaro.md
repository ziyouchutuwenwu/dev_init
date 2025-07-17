# manjaro

## 调试

### 打印 log

xfce 终端设置

```sh
通用 ->
  取消 -> 输出时滚动
  选择 -> 无限回滚
```

结果中搜索 `E:` 或者 `错误：` 即可看到错误的问题

### 暂停脚本

```python
input("暂停的信息")
```

## 注意

### 脚本运行前

manjaro_init.py 运行前, 普通用户配 git 代理, 不要用环境变量

```sh
~/.gitconfig
```

```sh
[http]
  proxy = socks5://127.0.0.1:1080
[https]
  proxy = socks5://127.0.0.1:1080
```

yay_init.py 运行前, 取消 git 代理, 用环境变量做代理

### 脚本运行后

鼠标风格选 DMZ

菜单设置

```sh
开始 ->
  右键 ->
    属性 ->
      general ->
        1 和 4 不选
        菜单宽度 360
        菜单高度 640
```

桌面右下角设置

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

主题

```sh
Matcha-light-azul
```

### 开机启动

PolicyKit 服务必须启动，否则基于 polkit 运行的程序会有问题，可以用 xfce-polkit 代替
