#! /usr/bin/env /bin/bash

echo "请根据具体mcu修改openocd的配置文件"
echo "可以telnet 127.0.0.1 4444来进行单个指令的调试"

openocd -f /home/mmc/dev/embedded/stm32/openocd/stm32f1x/jlink_board.cfg -c init -c 'reset halt' -c 'flash info 0' -c 'flash erase_sector 0 0 last' -c 'flash erase_check 0' -c shutdown