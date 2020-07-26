#! /usr/bin/env /bin/python

import sys
import os

if __name__ == "__main__":
    if len(sys.argv) == 1:
        print("stm32 board not found, f1, f4, h7 ?")
        exit(-1)

    board_type = sys.argv[1]
    board_full_name = "stm32%sx" % board_type

    cmd = (
        "openocd -f interface/jlink.cfg -c 'transport select swd' -f target/%s.cfg -c init -c 'reset halt' -c 'flash info 0' -c 'flash erase_sector 0 0 last' -c 'flash erase_check 0' -c shutdown"
        % board_full_name
    )
    os.system(cmd)
