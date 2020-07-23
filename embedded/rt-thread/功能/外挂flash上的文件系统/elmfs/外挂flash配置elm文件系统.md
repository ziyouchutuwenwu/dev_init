# 外挂 flash 配置 elm 文件系统

参考的[这里](https://www.rt-thread.org/document/site/application-note/components/dfs/an0012-dfs/)

## 先按照外挂 flash 的配置配置好

## menuconfig

```bash
RT-Thread Components > Device virtual file system  --->
  -*- Using device virtual file system
  [*] Using working directory
  (2) The maximal number of mounted file system
  (2) The maximal number of file system type
  (16) The maximal number of opened files
  [*] Enable elm-chan fatfs
    elm-chan's FatFs, Generic FAT Filesystem Module  --->
      Support long file name (3: LFN with dynamic LFN working buffer on the heap)  --->
        (X) 3: LFN with dynamic LFN working buffer on the heap
      (4096) Maximum sector size to be handled.
      [*] Enable sector erase feature

RT-Thread Components > POSIX layer and C standard library
  [*] Enable libc APIs from toolchain
```
