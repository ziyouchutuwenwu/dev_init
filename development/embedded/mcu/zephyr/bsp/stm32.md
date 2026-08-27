# stm32

## 说明

不建议自己移植，找最接近的板子修改参数即可。

## 步骤

### 准备

```sh
west boards | rg xxx
```

测试

```sh
west build -p auto -b blackpill_f411ce
```

```sh
# 原来位置
repo/zephyr/boards/weact/blackpill_f411ce/

# 复制一份
repo/zephyr/boards/xxx/stm32f411ceu6/
```

### 修改

board.yml， 注意 name 字段

```yml
board:
  name: stm32f411ceu6
  # 给人看得
  full_name: stm32f411ceu6 核心板
  ......
```

配置文件

```sh
所有配置文件的文件名需要和 name 字段一致
```

Kconfig

```sh
Kconfig 里面，宏定义也要一致，改成大写
```

openocd

```sh
openocd 里面，配置看情况修改
```

### 烧录

编译

```sh
west build -p auto -b stm32f411ceu6
```

烧录

```sh
west flash --runner openocd
```
