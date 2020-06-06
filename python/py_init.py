#!/usr/bin/env python
# -*- coding: UTF-8 -*-

from __future__ import print_function

import os
import sys

sys.path.append("..")
from py_mods import file
from py_mods import proc

if __name__ == "__main__":
    if True == proc.is_root():
        print("This program can not be run as root. Aborting.")
        exit(-1)

    os.system(
        "sudo apt install -y make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev"
    )
    os.system("curl https://pyenv.run | bash")

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
        "echo index-url = https://pypi.tuna.tsinghua.edu.cn/simple >> ~/.pip/pip.conf"
    )
    os.system("echo [install] >> ~/.pip/pip.conf")
    os.system("echo '# mac下默认的pip安装目录错误，需要自定义一下，版本号注意修改' >> ~/.pip/pip.conf")
    os.system(
        "echo '# install-option=--prefix=~/.pyenv/versions/3.6.5' >> ~/.pip/pip.conf"
    )
    print("请自己检查是否需要修改~/.pip/pip.conf的配置")
    exit(0)
