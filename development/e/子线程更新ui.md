# 子线程更新 ui

## UI 子线程刷新类

依赖精易模块

```e
.版本 2

.程序集 UI子线程刷新类
.程序集变量 _hwnd, 整数型, , , 需要支持子线程更新ui的窗口句柄
.程序集变量 _oldWindowProc, 长整数型
.程序集变量 _uiUpdateCallBack, 子程序指针, , , ui回调函数
.程序集变量 _triggerMsgId, 整数型, , , 通知ui线程的消息id，默认有个值

.子程序 _初始化, , , 当基于本类的对象被创建后，此方法会被自动调用

_triggerMsgId ＝ 9876


.子程序 _销毁, , , 当基于本类的对象被销毁前，此方法会被自动调用



' 依赖精易模块
' 如果这个方法改位置了，SetWindowLongA的最后一个参数也需要改
' 类回调_取类地址的第一个参数是目标函数所在序号

.子程序 newWindowProc, 整数型
.参数 hwnd, 整数型
.参数 msg, 整数型
.参数 wparam, 整数型
.参数 lparam, 整数型

.if (msg ＝ _triggerMsgId)
    调用子程序_ (val (_uiUpdateCallBack), , , , , , , , , , , , , , , )
.如果真结束
return (CallWindowProcA (_oldWindowProc, hwnd, msg, wparam, lparam))


.子程序 setUiUpdateProc, , 公开
.参数 uiUpdateCallBack, 子程序指针

_uiUpdateCallBack ＝ uiUpdateCallBack


.子程序 notifyUIUpdate, , 公开

PostMessageA (_hwnd, _triggerMsgId, 0, 0)


' 可以不调用

.子程序 setTriggerMsgId, , 公开
.参数 triggerMsgId, 整数型

_triggerMsgId ＝ triggerMsgId


.子程序 waitUIUpdate

SendMessageA (_hwnd, _triggerMsgId, 0, 0)



.子程序 initWithWindow, , 公开
.参数 hwnd, 整数型

_hwnd ＝ hwnd
_oldWindowProc ＝ GetWindowLongA (_hwnd, -4)
SetWindowLongA (_hwnd, -4, 类回调_取类地址 (3, 4, , ))
```

## 测试程序

```e
.版本 2

.程序集 窗口程序集_启动窗口
.程序集变量 ui, UI子线程刷新类

.子程序 __启动窗口_创建完毕

ui.initWithWindow (_启动窗口.GetHWnd ())
ui.setUiUpdateProc (&触发ui回调)

.子程序 _按钮1_被单击

线程_启动 (&子线程通知, , )


.子程序 子线程通知

ui.notifyUIUpdate ()


.子程序 触发ui回调

MsgBox (“触发ui回调”, 0, , )
```
