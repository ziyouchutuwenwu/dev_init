#!/usr/bin/env python
# -*- coding: UTF-8 -*-


import sys
import os


if __name__ == "__main__":
    if len(sys.argv) == 1:
        print("usage: %s board_type" % sys.argv[0])
        exit(-1)

    board_type = sys.argv[1]

    current_path = os.path.dirname(os.path.abspath(__file__))
    config_file_path = os.path.join(current_path, "templates", board_type, "jlink_board.cfg")

    cmd = "openocd -f %s -d2 -c 'init' -c ' reset_config none' -c 'reset halt' -c '%s lock 0' -c 'reset halt' -c shutdown" % (config_file_path, board_type)
    os.system(cmd)
