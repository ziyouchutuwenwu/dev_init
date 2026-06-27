# conf

## 说明

conf 里面是 value，对应 Kconfig 的 item, 要加前缀 `CONFIG_`

## 位置

按顺序加载，相同配置，后者覆盖前者

```sh
# soc 里面的名字，是根据 boards 里面拆出来的，比如 esp32s3_devkitc_procpu，去掉 devkitc 这个 board 名
socs/xxx.conf
boards/xxx.conf
prj.conf
```

## 例子

boards/esp32s3_devkitc_procpu.conf

```conf
CONFIG_DEMO1=y
CONFIG_DEMO2="value in board config"
```

socs/esp32s3_procpu.conf

```conf
CONFIG_DEMO1=n
CONFIG_DEMO2="value in socs config"
```

main.c

```c
#include <stdio.h>

int main(void)
{
  printf("编译目标: %s\n", CONFIG_BOARD_TARGET);

#ifdef CONFIG_DEMO1
  printf("CONFIG_DEMO1 = %d\n", CONFIG_DEMO1);
#else
  printf("CONFIG_DEMO1 未加载\n");
#endif

#ifdef CONFIG_DEMO2
  printf("CONFIG_DEMO2 = %s\n", CONFIG_DEMO2);
#else
  printf("CONFIG_DEMO2 未加载\n");
#endif
  return 0;
}
```

编译

```sh
west build -b esp32s3_devkitc/esp32s3/procpu
```

指定 xxx.conf

```sh
west build -b esp32s3_devkitc/esp32s3/procpu -- -DEXTRA_CONF_FILE=xxx.conf
```
