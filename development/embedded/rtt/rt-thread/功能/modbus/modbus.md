# modbus

## 配置

### libmodbus

```sh
RT-Thread online packages > IoT - internet of things
  [*] libmodbus: A Modbus library for RT-Thread
```

rtu 模式，如果开发板接 232 之类的口，对应看到原理图以后，设备名为 `/dev/uartx`

从 demo 里面看，似乎对于 slave 的支持很一般，解码都需要自己做

### freemodbus

```sh
RT-Thread online packages ->
  [*] FreeModbus: Modbus master and slave stack
```

## 总结

光 tcp 的话，用 libmodbus，rtu 的话，用 freemodbus

freemodbus

```sh
例子里面只有 rtu 的 master 和 slave 模式
```

libmodbus

```sh
tcp 的 master 和 slave 都有
rtu 只有 master
```
