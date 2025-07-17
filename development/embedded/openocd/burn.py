#!/usr/bin/env python
# -*- coding: UTF-8 -*-


import sys
import os


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("usage: %s board_type xxx.bin" % sys.argv[0])
        exit(-1)

    board_type = sys.argv[1]
    bin_name = sys.argv[2]

    current_path = os.path.dirname(os.path.abspath(__file__))
    config_file_path = os.path.join(current_path, "templates", board_type, "jlink_board.cfg")

    cmd = "openocd -f %s -d2 -c 'init' -c ' reset_config none' -c 'reset halt' -c 'flash write_image erase %s 0x08000000' -c 'verify_image %s 0x08000000' -c 'reset run' -c shutdown" % (config_file_path, bin_name, bin_name)
    os.system(cmd)
