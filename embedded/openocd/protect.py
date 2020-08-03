#!/usr/bin/env python
# -*- coding: UTF-8 -*-

import sys
import os

if __name__ == "__main__":
    if len(sys.argv) == 1:
        print("usage: %s board_type" % sys.argv[0])
        exit(-1)

    board_type = sys.argv[1]

    cmd = (
        "openocd -f interface/jlink.cfg -c 'transport select swd' -f target/%s.cfg -c 'init' -c ' reset_config none' -c 'reset halt' -c '%s lock 0' -c 'reset halt' -c shutdown"
        % (board_type, board_type)
    )
    os.system(cmd)
