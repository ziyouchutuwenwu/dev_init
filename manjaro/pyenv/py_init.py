#!/usr/bin/env python
# -*- coding: UTF-8 -*-

from __future__ import print_function

import os
import sys

sys.path.append("../..")
from py_mods import file
from py_mods import proc

if __name__ == "__main__":
    if True == proc.is_root():
        print("This program can not be run as root. Aborting.")
        exit(-1)

    os.system(
        "sudo pacman -S --noconfirm gcc gdb"
    )
    os.system("sudo pacman -S --noconfirm pyenv")

    path = os.path.expanduser("~")
    profile = path + "/" + ".profile"
    is_in_profile = file.is_in_profile(profile, 'eval "$(pyenv init -)"')
    if False == is_in_profile:
        os.system("echo '' >> ~/.profile")
        os.system("echo export PYENV_ROOT='\"$HOME/.pyenv\"' >> ~/.profile")
        os.system("echo export PATH='\"$PYENV_ROOT/bin:$PATH\"' >> ~/.profile")
        os.system("echo eval '\"$(pyenv init -)\"' >> ~/.profile")

    os.system("mkdir -p ~/.pip")
    os.system("echo [global] > ~/.pip/pip.conf")
    os.system(
        "echo index-url=https://mirrors.aliyun.com/pypi/simple/ >> ~/.pip/pip.conf"
    )
