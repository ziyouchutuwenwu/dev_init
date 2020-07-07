#! /bin/bash

picocom -b 115200 -s "sb -vv" -v "rb -vv" /dev/ttyUSB0
# tio -b 115200 /dev/ttyUSB0