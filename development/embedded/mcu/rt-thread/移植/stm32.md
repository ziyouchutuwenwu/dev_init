# stm32

## 说明

[标准版](https://www.rt-thread.org/document/site/#/rt-thread-version/rt-thread-standard/tutorial/make-bsp/stm32-bsp/STM32%E7%B3%BB%E5%88%97BSP%E5%88%B6%E4%BD%9C%E6%95%99%E7%A8%8B)

## 步骤

### 准备

stm32 的项目模板位置

```sh
bsp/stm32/libraries/templates/
```

模板内，对应芯片，复制一份出来

### stm32cubemx

用 stm32cubemx 创建项目

```sh
Project Manager -> Code Generator ->
  # 不勾选
  Generate peripheral initialization as a pair of '.c/.h' files per peripheral
```

复制生成出来的 Inc 和 Src 到 board/CubeMX_Config/

### 手动

Src/main.c 里, 复制到 board/board.c

```c
void SystemClock_Config(void) {
  ......
}
```

stm32xxx_hal_msp.c

```c
// 用 rtt 自己的 Error_Handler();
#include <drv_common.h>
```

board.h

```sh
STM32_FLASH_SIZE
STM32_SRAM_SIZE
```

链接脚本

```sh
# board/linker_scripts/link.lds
MEMORY 的 LENGTH 字段
```

board/Kconfig

```sh
SOC_
```

board/SConscript

```sh
CPPDEFINES
```

### menuconfig

```sh
scons --menuconfig
```

打包

```sh
scons --target=vsc --dist
```
