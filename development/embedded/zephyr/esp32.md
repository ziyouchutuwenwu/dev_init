# esp32

## 说明

esp32 的板子，需要一些特殊处理

## 步骤

烧录工具

```sh
uv pip install esptool

# 擦除
esptool --chip esp32-S3 --port /dev/ttyACM0 erase-flash
```

安装闭源 blob

```sh
west blobs fetch hal_espressif
```

查看

```sh
west blobs list hal_espressif
```
