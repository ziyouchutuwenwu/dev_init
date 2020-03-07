#! /usr/bin/env /bin/bash

echo "请根据具体mcu修改openocd的配置文件"
echo "可以telnet 127.0.0.1 4444来进行单个指令的调试"

openocd -f $HOME/dev/embedded/stm32/openocd/stm32f1x/jlink_board.cfg -c init -c 'reset halt' -c 'stm32f1x unlock 0' -c 'reset halt' -c shutdown