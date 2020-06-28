# modbus

RT-Thread online packages -> IoT - internet of things -> FreeModbus

- 接线流程

  - 开发板启用 uart2, 其引脚接 ttl 转 485
  - 开发板接开发机 debian, ttl 转 485 连的另外一根接 usb 转 485, usb 转 485 连 win7,上面跑 modbus 模拟器

- 用的 freemodbus 库
- 详细教程可以参考[这里](https://www.rt-thread.org/document/site/application-note/packages/freemodbus/an0036-freemodbus/)
- 必备调试器只有 windows 版，在[这里](https://www.modbustools.com/)下载，Modbus Poll 为模拟 master，Modbus Slave 为模拟 slave
