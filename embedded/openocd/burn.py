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
        "openocd -f interface/jlink.cfg -c 'transport select swd' -f target/%s.cfg -c init -c 'reset halt' -c 'flash write_image erase rtthread.bin 0x08000000' -c 'verify_image rtthread.bin 0x08000000' -c 'reset run' -c shutdown"
        % board_full_name
    )
    os.system(cmd)
