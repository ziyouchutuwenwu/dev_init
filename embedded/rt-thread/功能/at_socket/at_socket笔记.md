# at socket 配置

参考[链接](https://www.rt-thread.org/document/site/application-note/components/at/an0014-at-client/#at-socket)

## 先启用 uart2

## 开启 at device 软件包的支持

- 位置

```bash
RT-Thread online packages ---> IoT - internet of things ---> AT Device
```

- 配置参数

```bash
配置使用的设备为 ESP8266 设备；
配置 AT Client 设备名称和最大支持的接收数据长度；
配置 wifi ssid 和 wifi password 用于设备联网；
配置使用 laster 版本软件包；
```

## 开启 SAL 组件支持

- 位置

```bash
RT-Thread Components
    Network
        Socket abstraction laye
            protocol stack implement
                [*]Support AT Commands stack
            [*]Enable BSD socket operated by the file system API
```

## 注意

- 模块串口和开发板的串口反接
- 注意供电, vcc 要接
- 如果还有解决不了的问题，看[这里](https://www.rt-thread.org/qa/forum.php?mod=viewthread&tid=11919&extra=page%3D1%26filter%3Dtypeid%26typeid%3D5)
