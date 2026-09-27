# Kconfig

## 说明

Kconfig 是菜单

## 位置

Kconfig

```sh
根目录
  默认加载

任意路径
  编译时指定
  west build -b stm32f411ceu6 -p always -d debug -- -DKCONFIG_ROOT=boards/stm32f411ceu6/Kconfig
```

## 例子

Kconfig

```conf
source "Kconfig.zephyr"

source "$(APP_DIR)/configs/Kconfig1"
source "$(APP_DIR)/configs/Kconfig2"
```

Kconfig1

```conf
menu "demo1 菜单"

config DEMO1
    bool "这是 demo1 菜单显示的文本"
    default n

endmenu
```

Kconfig2

```conf
menu "demo2 菜单"

config DEMO2
    string "这是 demo2 菜单显示的文本"
    default "in kconfig2"

endmenu
```
