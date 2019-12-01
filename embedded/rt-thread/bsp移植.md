# [参考链接]

- [STM32系列BSP制作教程](https://github.com/RT-Thread/rt-thread/blob/master/bsp/stm32/docs/STM32%E7%B3%BB%E5%88%97BSP%E5%88%B6%E4%BD%9C%E6%95%99%E7%A8%8B.md)
- [STM32系列外设驱动添加指南](https://github.com/RT-Thread/rt-thread/blob/master/bsp/stm32/docs/STM32%E7%B3%BB%E5%88%97%E5%A4%96%E8%AE%BE%E9%A9%B1%E5%8A%A8%E6%B7%BB%E5%8A%A0%E6%8C%87%E5%8D%97.md)

## 复制模板

- bsp/stm32/libraries/templates下面复制你的型号的模板

## 生成cubeMX项目

- 创建跟你mcu一样的项目，然后 `import` 导入 board/CubeMX_Config/CubeMX_Config.ioc 项目模板（这样才可以保留原来的cubeMX的配置）
- 修改配置，生成代码。复制 Inc 和 Src 目录到 board/CubeMX_Config下覆盖
- 修改 board/CubeMX_Config/Inc/stm32f4xx_hal_conf.h，注释掉 `#define HAL_EXTI_MODULE_ENABLED`， 否则编译失败，这是由于rtt使用的stm32的源码库较低，cubeMX用的比较新
- 从 board/CubeMX_Config 里面找到 main.c，复制 SystemClock_Config() 到 board/board.c 里面，这是唯一需要手工复制的函数，如果不复制，可能会出现烧录以后失去响应的问题
- `Src/stm32f4xx_hal_msp.c 里面的一些类似 HAL_XXX_MspInit 的函数，未必会使用到，测试下来发现adc会用到，i2c，spi等都不会用到，不过使用cubeMX做代码生成，不需要考虑此处的问题`
- board.h 里面，存放着 flash 和 ram 的大小，需要检查这里是否需要修改

## bsp部分的注意点

- stm32XXxx_hal_conf.h 启用哪些外设驱动，这个里面的宏定义就是cubeMX里面的设备选项开关
- stm32XXxx_hal_msp.c 外设驱动的配置代码

## 修改board/Kconfig

- 搜索 config SOC_STM32, 改为相应的芯片型号
- 如果需要i2c等配置，而当前的Kconfig里面没有的话，可以从别的bsp里面借鉴一下

## 修改flash，ram大小相关配置

- board/board.h
  - 修改 STM32_FLASH_SIZE
  - 修改 STM32_SRAM_SIZE

- board/linker_scripts/link.sct, xxxxxxxx 为flash大小，yyyyyyyy 为ram大小

```bash
LR_IROM1 0x08000000 xxxxxxxx  {    ; load region size_region
  ER_IROM1 0x08000000 xxxxxxxx  {  ; load address = execution address
   *.o (RESET, +First)
   *(InRoot$$Sections)
   .ANY (+RO)
  }
  RW_IRAM1 0x20000000 yyyyyyyy  {  ; RW data
   .ANY (+RW +ZI)
  }
}
```

- board/linker_scripts/link.icf, 改 __ICFEDIT_region_ROM_end__ 和 __ICFEDIT_region_RAM_end__ ，注意end地址，是完整大小减1

```bash
define symbol __ICFEDIT_region_ROM_start__ = 0x08000000;
define symbol __ICFEDIT_region_ROM_end__   = 0x0801FFFF;
define symbol __ICFEDIT_region_RAM_start__ = 0x20000000;
define symbol __ICFEDIT_region_RAM_end__   = 0x20004FFF;
```

- board/linker_scripts/link.lds，修改对应区域

```bash
MEMORY
{
    ROM (rx) : ORIGIN = 0x08000000, LENGTH = 128k /* 128KB flash */
    RAM (rw) : ORIGIN = 0x20000000, LENGTH =  20k /* 20K sram */
}
```

## 修改board/SConscript, 看看芯片等信息有没有错误

- 搜索 CPPDEFINES, 改成你的芯片对应的型号
- 根据你的芯片型号，修改下面对应的汇编启动文件 xxxxxx.s, 如果不知道用哪个，可以用cubeMX生成项目以后找，看用的是哪个文件

```bash
if rtconfig.CROSS_TOOL == 'gcc':
    src += [startup_path_prefix + '/STM32F1xx_HAL/CMSIS/Device/ST/STM32F1xx/Source/Templates/gcc/startup_stm32f103xb.s']
elif rtconfig.CROSS_TOOL == 'keil':
    src += [startup_path_prefix + '/STM32F1xx_HAL/CMSIS/Device/ST/STM32F1xx/Source/Templates/arm/startup_stm32f103xb.s']
elif rtconfig.CROSS_TOOL == 'iar':
    src += [startup_path_prefix + '/STM32F1xx_HAL/CMSIS/Device/ST/STM32F1xx/Source/Templates/iar/startup_stm32f103xb.s']
```