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
        "openocd -f interface/jlink.cfg -c 'transport select swd' -f target/%s.cfg -c init -c 'reset halt' -c '%s unlock 0' -c 'reset halt' -c shutdown"
        % (board_full_name, board_full_name)
    )
    os.system(cmd)
