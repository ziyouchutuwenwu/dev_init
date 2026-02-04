# esp32

## 说明

esp32 的板子，需要一些特殊处理

## 步骤

烧录工具

```sh
uv pip install esptool
```

安装闭源 blob

```sh
west blobs fetch hal_espressif --auto-accept
```

会报 click-through 相关错，修改 `repo/modules/hal/espressif/zephyr/module.yml`

```yaml
- path: lib/esp32s3/libcoexist.a
  type: lib
  # 添加这个, true 则需要 auto-accept
  click-through: true
```

```sh
:%s/\(^\s*\)type:\s*lib\s*$/\1type: lib\r\1click-through: true/g
```

查看

```sh
west blobs list hal_espressif
```
