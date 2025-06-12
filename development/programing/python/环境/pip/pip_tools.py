#!/usr/bin/env python
# -*- coding: UTF-8 -*-


import sys
sys.dont_write_bytecode = True

import os

if __name__ == "__main__":

    cmd = "pip install pip --upgrade"
    os.system(cmd)

    cmd = "pip install ansible --upgrade"
    os.system(cmd)

    cmd = "pip install stegoveritas-binwalk --upgrade"
    os.system(cmd)

    cmd = "pip install litecli --upgrade"
    os.system(cmd)

    cmd = "pip install mycli --upgrade"
    os.system(cmd)

    cmd = "pip install pgcli --upgrade"
    os.system(cmd)

    cmd = "pip install sqlmap --upgrade"
    os.system(cmd)

    cmd = "pip install scons --upgrade"
    os.system(cmd)

    cmd = "pip install you-get --upgrade"
    os.system(cmd)

    cmd = "pip install yt-dlp --upgrade"
    os.system(cmd)

    cmd = "pip install prettytable --upgrade"
    os.system(cmd)

    cmd = "pip install cython --upgrade"
    os.system(cmd)

    cmd = "pip install nuitka --upgrade"
    os.system(cmd)

    cmd = "pip install uv --upgrade"
    os.system(cmd)

    # pip search目前有问题，需要使用下面这个, 命令是 pip_search
    cmd = "pip install pip-search --upgrade"
    os.system(cmd)
