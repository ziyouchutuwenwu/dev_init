# 这里介绍FAL的用法

## FAL准备工作

- board/Kconfig添加

```bash
config BSP_USING_ON_CHIP_FLASH
    bool "Enable on-chip FLASH"
    default n
```

- `scons --menuconfig` 选中

```bash
RT-Thread online packages -> system packages -> 启用fal，如果只考虑片上flash的话，SFUD不要勾选
Hardware Drivers Config -> On-chip Peripheral Drivers，启用 Enable on-chip FLASH
```

- on_chip_flash 目录复制到你的 applications 目录
- SConscript 添加如下

```python
CPPPATH += [cwd + '/on_chip_flash']
src内添加
on_chip_flash/romfs_init.c
on_chip_flash/fal_demo.c
on_chip_flash/lfs_demo.c
on_chip_flash/elm_demo.c
```

- 测试命令

```bash
fal probe xxx
fal read 0 10
fal write xxx
```

## lfs准备工作

- `scons --menuconfig` 选中

```bash
RT-Thread Components -> Device virtual filesystem, 启用 虚拟文件系统, 注意 the maximal number of mounted file system, the maximal number of file system type, the maximal number of opened files，尽量设置大一些
RT-Thread Components -> Device Drivers, 启用 Using MTD Nor Flash device drivers
RT-Thread Components -> POSIX layer and C standard library, 启用 Enable libc APIs from toolchain
RT-Thread online packages -> system packages -> 启用Littlefs, 注意，disk block size 是扇区大小, lfs enable wear leveling. 0 is disable，这个设置为100，为0有时候会崩
```

- 需要注意的地方

```bash
需要根据你需要的大小修改rtt自带驱动里面的`const struct fal_flash_dev stm32_onchip_flash_xxk`，驱动的相对路径为 `libraries/HAL_Drivers/drv_flash/drv_flash_f4.c`，这个结构体里面的blk为扇区大小，建议改成 `2048` 或者 `4096`
```

## romfs准备工作

- `scons --menuconfig` 选中

```bash
RT-Thread Components -> Device virtual filesystem, 启用 虚拟文件系统, Enable Readonly file system on flash.
```

- 注意，需要使用下面的命令重新生成romfs的源码

```bash
python2 ./rt-thread/tools/mkromfs.py 你的文件目录 rt-thread/components/dfs/filesystems/romfs/romfs.c
```

## 注意

- 已知的问题：**在某些板子上，fal和lfs不兼容，同时启用以后，会导致fal的erase挂掉，当然lfs的格式化也会挂掉**

## elm貌似格式化会报错，不管了
