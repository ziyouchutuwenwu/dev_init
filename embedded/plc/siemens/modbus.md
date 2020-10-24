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
