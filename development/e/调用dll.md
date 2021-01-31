# 调用 dll

## dll

```pascal
library Project1;

uses
  SysUtils,
  Classes;

{$R *.res}

function add(Value1:integer;value2:integer):integer;stdcall;
begin
  Result:=Value1+value2;
end;

exports
  add;

begin
end.
```

## 测试程序

dll 命令

```e
.版本 2

.DLL命令 DLL命令1, 整数型, "D:\\Desktop\\aaa\\dll\\Debug\\Win32\\Project1.dll", "add"
    .参数 a, 整数型
    .参数 b, 整数型
```

测试 exe

```e
.版本 2

.程序集 窗口程序集_启动窗口

.子程序 __启动窗口_创建完毕



.子程序 _按钮1_被单击
.局部变量 x, 整数型

x ＝ DLL命令1 (11, 22)
MsgBox (str (x), 0, , )
```
