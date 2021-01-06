# HMI

先需要激活 HMI 的授权，如果是在 twincat 里面，模拟，直接 7 天试用授权即可。如果需要在 plc 里面跑，需要正式授权

## 显示中文

视图管理器，TargetVisualization，这个`必须`要建，不然会出现很多诡异的问题，比如按钮调用 st 代码时候，无法调用方法
显示已使用的视图，设置，使用 Unicode 字符串

## 例子

Textfield

```sh
texts里面的text设置为%s
text variable设置为某个变量，比如
MAIN.deomo_info
```

Button

```sh
button 的 OnMouseClick 事件选择 `执行ST代码`
Main.demo_action();
```

## 调试时非全屏显示的设置

调试时候，选择 local 的话，默认 hmi 会全屏
需要去 TargetVisualization 里面，关闭 Start Client on Startup 的选项
