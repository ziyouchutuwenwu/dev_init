# at socket 配置

参考[链接](https://www.rt-thread.org/document/site/application-note/components/at/an0014-at-client/#at-socket)

## 先启用 uart2

## 开启 at device 软件包的支持

- 位置

```bash
RT-Thread online packages >
  IoT - internet of things >
    AT DEVICE: RT-Thread AT component porting or samples for different device
       [*]  Espressif ESP8266  --->
```

- 配置参数

```bash
配置使用的设备为 ESP8266 设备；
配置 AT Client 设备名称和最大支持的接收数据长度；
配置 wifi ssid 和 wifi password 用于设备联网；
缓冲区大小需要注意，可以设置大一点，不然会提示`Read response buffer failed. The Response buffer size is out of buffer size(xxx)!`，xxx为实际的缓冲区大小
配置使用 laster 版本软件包；
```

## 开启驱动部分的支持

- 位置

```bash
RT-Thread Components
  Network
    Socket abstraction layer
      protocol stack implement
        [*]Support AT Commands stack
        [*]Enable BSD socket operated by the file system API
    Enable AT commands
      -*-   Enable AT commands client
      -*-     Enable BSD Socket API support by AT commnads
      // 这里是选择显示at命令日志
      [ ]     Enable print RAW format AT command communication data
     (128)   The maximum lenght of AT Commonds buffer
```

## 注意

- 模块串口和开发板的串口反接
- 注意供电, vcc 要接 3.3v，如果出现提示超时之类的，可以换一下供电
- 如果提示缓冲区不够

```bash
比如 [E/at.clnt] Read response buffer failed. The Response buffer size is out of buffer size(xxx)
可以在 at.client.c 的 at_create_resp 函数上下断点观察流程
```

- 如果还有解决不了的问题，看[这里](https://www.rt-thread.org/qa/forum.php?mod=viewthread&tid=11919&extra=page%3D1%26filter%3Dtypeid%26typeid%3D5)
