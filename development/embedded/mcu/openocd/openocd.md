# openocd

## 用法

调试

```sh
openocd -f interface/cmsis-dap.cfg -f target/芯片型号.cfg
```

擦除

```sh
openocd -f interface/cmsis-dap.cfg -f target/stm32f4x.cfg -c 'init; halt; flash erase_sector 0 0 last; shutdown'
```

烧录

```sh
openocd -f interface/cmsis-dap.cfg -f target/stm32f4x.cfg -c 'init; halt; flash write_image erase rtthread.bin 0x08000000; reset; shutdown'
```
