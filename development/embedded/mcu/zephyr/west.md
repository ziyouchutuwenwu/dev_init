# west

## 说明

编译时，默认生成 compile_commands.json，c 的补全靠这个

## 用法

查看所有板子

```sh
west boards
```

编译

```sh
# 指定哪个板
# -p 是设置要不要清理 build 目录
west build -b esp32s3_devkitc/esp32s3/procpu -p always

# -- 代表后面的参数是给 cmake的
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
