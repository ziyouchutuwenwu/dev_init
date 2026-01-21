# lfs

## 说明

外挂 flash 上使用 lfs

参考的 [这里](https://www.rt-thread.org/document/site/application-note/components/dfs/an0027-littlefs/)

## 配置

### 准备

先按照外挂 flash 的配置配置好

### menuconfig

```sh
RT-Thread Components ---> Device virtual file system
  [*] Using device virtual file system

RT-Thread online packages > system packages > Littlefs: A high-integrity embedded file system
  [*] Littlefs: A high-integrity embedded file system
    (256) disk read size
    (256) disk write size
    (4096) disk block size
    (256) lfs r/w cache size
    (100) lfs enables wear leveling. 0 is disable.
    (512) lfs lookahead size
```

## 注意

demo 代码里面的`dfs_mount`和`dfs_mkfs`的参数，DEVICE_NAME, lfs 和 elm 是不一样的
