# freebsd

## 说明

xfce 现在有 bug, 建议用无桌面的 root 脚本

## 配置

### 准备工作

先开启 ssh 的 root 登录，然后 scp 过去

### 代理

#### 无桌面

root 脚本，pkg 支持 `HTTP_PROXY` 和 `HTTPS_PROXY`

#### 桌面

带桌面的脚本，配置非 root 用户的 git 代理

不要用 `HTTP_PROXY` 和 `HTTPS_PROXY`

```sh
~/.gitconfig
```

```sh
[http]
  proxy = socks5://127.0.0.1:1080
[https]
  proxy = socks5://127.0.0.1:1080
```

### 脚本结束

#### 分辨率调整

qemu 下，如果显示不全，可以手动调节分辨率

```sh
设置 -> 设置管理器 -> 显示
```

分辨率改成

```sh
1280x720* 16:9
```

#### 调整时间显示

桌面右上角设置

```sh
时间 -> 右键 -> 属性
  外观 -> 布局 -> 数字式
  时钟选项 -> 布局 -> 仅时间
  时间 -> 格式 -> 自定义格式 -> %Y-%m-%d %H:%M:%S
```

#### 终端设置

xfce 终端设置

```sh
外观 ->
  字体 -> Monaco 11
  默认几何属性 -> 100 22
```

#### 鼠标迟滞

如果鼠标有迟滞, 尝试使用 evdev 驱动

```sh
sudo pkg remove -f xf86-input-libinput
sudo pkg install -y xf86-input-evdev
```

禁用合成器

```sh
设置 -> 窗口管理器微调 -> 合成器，取消勾选
```

cli 模式下，禁用鼠标似乎效果也有一点

### 辅助工具

```sh
bsdconfig
bsdinstall
```
