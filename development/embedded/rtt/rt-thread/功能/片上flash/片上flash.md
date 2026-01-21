# 片上 flash

## 说明

片上 flash 读写，这里介绍 FAL 的用法

## 准备工作

### FAL 准备

board/Kconfig 添加

```sh
config BSP_USING_ON_CHIP_FLASH
    bool "Enable on-chip FLASH"
    default n
```

启用 fal

```sh
RT-Thread online packages --->
  system packages --->
    [*]fal: Flash Abstraction Layer implement. Manage flash device and partition.  --->
    启用fal，如果只考虑片上flash的话，SFUD不要勾选
```

on_chip_flash 目录复制到你的 applications 目录

SConscript 添加如下

```python
CPPPATH += [cwd + '/on_chip_flash']

on_chip_flash/romfs_init.c
on_chip_flash/fal_demo.c
on_chip_flash/lfs_demo.c
on_chip_flash/elm_demo.c
```

测试命令

```sh
fal probe xxx
fal read 0 10
fal write xxx
```

### lfs 准备

`scons --menuconfig` 选中

```sh
RT-Thread Components --->
  Device virtual file system
  [*] Using device virtual file system
  注意，以下参数，尽量设置大一些：
    the maximal number of mounted file system
    the maximal number of file system type
    the maximal number of opened files
```

```sh
RT-Thread Components --->
  Device Drivers --->
    [*] Using MTD Nor Flash device drivers
```

```sh
RT-Thread Components --->
  POSIX layer and C standard library --->
    [*] Enable libc APIs from toolchain
```

```sh
RT-Thread online packages --->
  system packages --->
    [*] Littlefs: A high-integrity embedded file system  ---->
  注意:
    disk block size 是扇区大小
    lfs enable wear leveling. 0 is disable，这个设置为 100，为 0 有时候会崩
```

需要注意的地方

```sh
需要根据你需要的大小修改rtt自带驱动里面的`const struct fal_flash_dev stm32_onchip_flash_xxk`
驱动的相对路径为 `libraries/HAL_Drivers/drv_flash/drv_flash_f4.c`
这个结构体里面的blk_size为扇区大小，建议改成 `2048` 或者 `4096`
```

### romfs 准备

使用场景：如果需要挂载多个 fs，可以使用 romfs 先创建几个文件夹，然后启动以后把几个 fs 分别挂载到不同的目录

```sh
RT-Thread Components --->
  Device virtual file system
  [*] Using device virtual file system
    [*] Enable ReadOnly file system on flash
```

注意，需要使用下面的命令重新生成 romfs 的源码

```sh
python2 ./rt-thread/tools/mkromfs.py 你的文件目录 ./rt-thread/components/dfs/filesystems/romfs/romfs.c
```

## 注意

已知的问题：**在某些板子上，fal 和 lfs 不兼容，同时启用以后，会导致 fal 的 erase 挂掉，当然 lfs 的格式化也会挂掉**

elm 貌似格式化会报错，不管了
