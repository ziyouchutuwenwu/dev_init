#!/usr/bin/env /bin/bash

# systemctl restart udev
udevadm control --reload-rules
udevadm trigger