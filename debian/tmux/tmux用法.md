# tmux 用法

## 常用指令

```sh
ctrl+b d 脱离当前会话；tmux attach 重新进入

ctrl+b c 创建window
ctrl+b , 重命名window
ctrl+b p 上一个window
ctrl+b n 下一个window
ctrl+b & 关闭window

ctrl+b " 水平分割当前window
ctrl+b % 垂直分割当前window
ctrl+b o 在分割的panel里面切换
ctrl+b x 关闭当前panel

ctrl+b ctrl+方向键 调整panel大小
ctrl+b Space 切换panel的布局
ctrl+b 方向键 移动光标以选择面板
ctrl+b { 向前交换panel
ctrl+b } 向后交换panel
```

## 鼠标支持

```sh
vim ~/.tmux.conf
set-option -g mouse on
```

```sh
用鼠标点击窗格来激活该窗格；
用鼠标拖动调节窗格的大小（拖动位置是窗格之间的分隔线）；
用鼠标点击来切换活动窗口（点击位置是状态栏的窗口名称）；
开启窗口/窗格里面的鼠标支持，用鼠标回滚显示窗口内容，按下shift的同时用鼠标选取文本，使用 ctrl+shift+c、ctrl+shift+v 的方式进行复制粘贴。
```
