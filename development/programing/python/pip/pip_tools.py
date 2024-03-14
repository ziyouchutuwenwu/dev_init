#!/usr/bin/env python
# -*- coding: UTF-8 -*-

import os
import sys

pwd = os.path.dirname(os.path.abspath(__file__))
module_path = "%s/../../../../" % pwd
sys.path.append(module_path)
from py_mods import file

if __name__ == "__main__":

    cmd = "pip install pip --upgrade"
    os.system(cmd)

    cmd = "pip install ansible --upgrade"
    os.system(cmd)

    cmd = "pip install stegoveritas-binwalk --upgrade"
    os.system(cmd)

    cmd = "pip install bpytop --upgrade"
    os.system(cmd)

    cmd = "pip install litecli --upgrade"
    os.system(cmd)

    cmd = "pip install mycli --upgrade"
    os.system(cmd)

    cmd = "pip install pgcli --upgrade"
    os.system(cmd)

    cmd = "pip install sqlmap --upgrade"
    os.system(cmd)

    cmd = "pip install pysocks --upgrade"
    os.system(cmd)

    cmd = "pip install pymetasploit3 --upgrade"
    os.system(cmd)

    cmd = "pip install selenium --upgrade"
    os.system(cmd)

    cmd = "pip install httpie --upgrade"
    os.system(cmd)

    cmd = "pip install scons --upgrade"
    os.system(cmd)

    cmd = "pip install uiautomator2 weditor --upgrade"
    os.system(cmd)

    cmd = "pip install you-get --upgrade"
    os.system(cmd)

    cmd = "pip install yt-dlp --upgrade"
    os.system(cmd)

    cmd = "pip install prettytable --upgrade"
    os.system(cmd)

    # 编译为 c 的工具
    cmd = "pip install cython nuitka --upgrade"
    os.system(cmd)

    # pip search目前有问题，需要使用下面这个, 命令是 pip_search
    cmd = "pip install pip-search --upgrade"
    os.system(cmd)

    cmd = "pip install pyinotify --upgrade"
    os.system(cmd)
    path = os.path.expanduser("~")
    profile = path + "/" + ".profile"
    file.set_to_file(profile, 'alias pyfilemon="python -m pyinotify -v"', need_new_blank_line=True)
