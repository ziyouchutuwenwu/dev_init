#! /usr/bin/env /bin/python

import sys
import os

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("usage: %s board_type xxx.bin" % sys.argv[0])
        exit(-1)

    board_type = sys.argv[1]
    bin_name = sys.argv[2]

    cmd = (
        "openocd -f interface/jlink.cfg -c 'transport select swd' -f target/%s.cfg -c 'init' -c ' reset_config none' -c 'reset halt' -c 'flash write_image erase %s 0x08000000' -c 'verify_image %s 0x08000000' -c 'reset run' -c shutdown"
        % (board_type, bin_name, bin_name)
    )
    os.system(cmd)
