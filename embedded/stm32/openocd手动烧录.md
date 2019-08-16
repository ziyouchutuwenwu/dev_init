# 流程

- 连接到openocd的shell

```bash
telnet 127.0.0.1 4444
```

- 输入命令

```bash
halt
flash probe 0
```

会看到一个地址

```bash
flash write_image erase /home/mmc/dev/embedded/rtt/rt-thread/bsp/stm32/stm32f103-mini-system/rtthread.bin 0x08000000
```

验证

```bash
verify_image /home/mmc/dev/embedded/rtt/rt-thread/bsp/stm32/stm32f103-mini-system/rtthread.bin 0x08000000
```
