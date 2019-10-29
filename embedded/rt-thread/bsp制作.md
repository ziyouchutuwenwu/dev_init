# [参考链接](https://github.com/RT-Thread/rt-thread/blob/master/bsp/stm32/docs/STM32%E7%B3%BB%E5%88%97BSP%E5%88%B6%E4%BD%9C%E6%95%99%E7%A8%8B.md)

## 复制模板

- bsp/stm32/libraries/templates下面复制你的型号的模板

## 生成cubeMX项目

- 打开创建的项目, main.c里面，复制 SystemClock_Config() 到 board/board.c里面，这是唯一一个需要手工复制的函数
board.h 里面，存放着flash和ram的大小，需要检查这里是否需要修改
- 或者创建一个项目，然后在cubeMX里面选择import已有的ioc，这样可以保留原来的配置

## 修改board/Kconfig

- 主要是芯片型号等部分，不能写错
- 如果需要i2c等配置，而当前的Kconfig里面没有的话，可以从别的bsp里面借鉴一下

## 修改linker_scripts目录下文件，看看flash，ram大小等等

- 三个文件都要看，建议找类似大小的芯片借鉴一下

## 修改board/SConscript，看看芯片等信息有没有错误
