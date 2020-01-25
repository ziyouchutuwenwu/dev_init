# 这里介绍FAL的用法

## 准备工作

- board/Kconfig添加

```bash
config BSP_USING_ON_CHIP_FLASH
    bool "Enable on-chip FLASH"
    default n
```

- `scons --menuconfig` 选中

```bash
RT-Thread online packages -> system packages -> 启用fal，如果只考虑片上flash的话，SFUD不要勾选
RT-Thread Components -> Device Drivers, 启用 Using MTD Nor Flash device drivers
Hardware Drivers Config -> On-chip Peripheral Drivers，启用 Enable on-chip FLASH
```

- on_chip_flash 目录复制到你的 applications 目录
- SConscript 添加如下

```python
CPPPATH += [cwd + '/on_chip_flash']
src内添加
on_chip_flash/fal_demo.c
on_chip_flash/fs_demo.c
```

- 测试命令

```bash
fal probe xxx
fal read 0 10
fal write xxx
```

## 已知的问题：4.02版的rtt，flash做erase的时候，会卡死, 需要使用313的rtt
