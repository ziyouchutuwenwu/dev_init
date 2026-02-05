# west

## 用法

查看所有板子

```sh
west boards
```

编译

```sh
# 这个是双核，比较特殊
west build -b esp32s3_devkitc/esp32s3/procpu --pristine

# 指定使用某个 conf
west build -b esp32s3_devkitc/esp32s3/procpu -d xxx_dir -- -DOVERLAY_CONFIG=./overlay-bt.conf
```

menuconfig，需要先编译

```sh
west build -t menuconfig
```

烧录

```sh
west flash
west flash -d xxx_dir
```
