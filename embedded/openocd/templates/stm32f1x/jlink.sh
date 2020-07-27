#! /usr/bin/env /bin/bash

CURRENT_DIR=$(cd "$(dirname "$0")";pwd)
openocd -f $CURRENT_DIR/jlink_board.cfg