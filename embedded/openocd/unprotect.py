#! /usr/bin/env /bin/python

import sys
import os

if __name__ == "__main__":
    if len(sys.argv) == 1:
        print("usage: %s board_type xxx.bin" % sys.argv[0])
        exit(-1)

    board_type = sys.argv[1]

    cmd = (
        "openocd -f interface/jlink.cfg -c 'transport select swd' -f target/%s.cfg -c init -c 'reset halt' -c '%s unlock 0' -c 'reset halt' -c shutdown"
        % (board_type, board_type)
    )
    os.system(cmd)
