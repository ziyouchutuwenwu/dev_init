# esp32

## 说明

esp32 的板子，需要一些特殊处理

## 步骤

烧录工具

```sh
uv pip install esptool

# 擦除
esptool --port /dev/ttyACM0 erase-flash

# 烧单独 bin
esptool --port /dev/ttyACM0 write-flash 0 ./zephyr.bin
```

安装闭源 blob

```sh
west blobs fetch hal_espressif
```

查看

```sh
west blobs list hal_espressif
```
