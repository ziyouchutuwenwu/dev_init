# [参考链接]

- [STM32系列BSP制作教程](https://github.com/RT-Thread/rt-thread/blob/master/bsp/stm32/docs/STM32%E7%B3%BB%E5%88%97BSP%E5%88%B6%E4%BD%9C%E6%95%99%E7%A8%8B.md)
- [STM32系列外设驱动添加指南](https://github.com/RT-Thread/rt-thread/blob/master/bsp/stm32/docs/STM32%E7%B3%BB%E5%88%97%E5%A4%96%E8%AE%BE%E9%A9%B1%E5%8A%A8%E6%B7%BB%E5%8A%A0%E6%8C%87%E5%8D%97.md)

## 复制模板

- bsp/stm32/libraries/templates下面复制你的型号的模板

## 生成cubeMX项目

- 创建跟你mcu一样的项目，修改配置，生成代码。复制 Inc 和 Src 目录到 board/CubeMX_Config下覆盖
- 修改 board/CubeMX_Config/Inc/stm32f4xx_hal_conf.h，注释掉 `#define HAL_EXTI_MODULE_ENABLED`， 否则编译失败，这是由于rtt使用的stm32的源码库较低，cubeMX用的比较新
- 从 board/CubeMX_Config 里面找到 main.c，复制 SystemClock_Config() 到 board/board.c 里面，这是唯一需要手工复制的函数，如果不复制，可能会出现烧录以后失去响应的问题

## 修改board/Kconfig

- 搜索 config SOC_STM32, 改为相应的芯片型号
- 如果需要i2c等配置，而当前的Kconfig里面没有的话，可以从别的bsp里面借鉴一下

## 修改flash，ram大小相关配置

- 见 [bsp_helper.py](./bsp_helper.py)

## 修改board/SConscript, 看看芯片等信息有没有错误

- 搜索 CPPDEFINES, 改成你的芯片对应的型号，具体写法参考CPPDEFINES上面的内容里面改
- 根据你的芯片型号，修改下面对应的汇编启动文件 `xxxxxx.s`, 如果不知道用哪个，可以用cubeMX生成项目以后找，看用的是哪个文件

```bash
if rtconfig.CROSS_TOOL == 'gcc':
    src += [startup_path_prefix + '/STM32F1xx_HAL/CMSIS/Device/ST/STM32F1xx/Source/Templates/gcc/startup_stm32f103xb.s']
elif rtconfig.CROSS_TOOL == 'keil':
    src += [startup_path_prefix + '/STM32F1xx_HAL/CMSIS/Device/ST/STM32F1xx/Source/Templates/arm/startup_stm32f103xb.s']
elif rtconfig.CROSS_TOOL == 'iar':
    src += [startup_path_prefix + '/STM32F1xx_HAL/CMSIS/Device/ST/STM32F1xx/Source/Templates/iar/startup_stm32f103xb.s']
```
