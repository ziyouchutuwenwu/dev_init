# modbus

目前使用的都是高版本，具体高低版本的区别见[这里](http://www.ad.siemens.com.cn/productportal/Prods/S7-1200_PLC_EASY_PLUS/SmartSMS/016.html)

## 指令位置

通信，通信处理器，MODBUS(RTU)

## plc 配置

S7-1200 和 CB1241, CB1241 的属性里面配置好硬件的波特率等等

## 接线

```txt
TRA 接 B
TRB 接 A
GND 可不接
```

## 代码见例子

## 备注

1. 状态字需要捕捉，完成位=1 时将 STATUS MOVE 出来，光看是看不到的
2. 初始化的背景块的 MODE 改了吗，如果是 RS485，MODE=4，改完初始值后下载，然后 stop - run 才能生效
3. DATA_PTR 不能是优化块
4. 不建议定时触发 MASTER，建议完成位触发下一个

## 其他需要注意的

### ob83

ob83 对应 Pull or plug of modules, 主要用于模块的插拔时的响应. Event_Class 如果是 16#38,则需要重新调用 Modbus_Comm_Load 做 modbus 的初始化

```delphi
IF #Event_Class = 16#38 THEN
    // XXX 在默认变量表, 系统常量里面可以看到
    IF #LADDR = XXX THEN
        // modbus 重新初始化
    END_IF;
END_IF;
```

### ob86

ob83 对应 分布式 IO 站点故障和恢复, 通过 OB86 接口区的输入变量“16#Event_Class”判断故障的模块和类型：事件类型 16#39 表示站点故障，事件类型 16#38 表示站点恢复。

```pascal
IF #Event_Class = 16#38 THEN
    // XXX 在默认变量表, 系统常量里面可以看到
    IF #LADDR = XXX THEN
        // modbus 重新初始化
    END_IF;
END_IF;
```
