#!/usr/bin/env python
# -*- coding: UTF-8 -*-

from __future__ import print_function

import os
import sys

pwd = os.path.split(os.path.realpath(__file__))[0]
module_path = "%s/../../" % pwd
sys.path.append(module_path)
from py_mods import file
from py_mods import proc

if __name__ == "__main__":
    if True == proc.is_root():
        print("This program can not be run as root. Aborting.")
        exit(-1)

    os.system("git clone https://github.com/rbenv/rbenv.git ~/.rbenv")
    os.system(
        "git clone git://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build"
    )
    os.system(
        "git clone git://github.com/rkh/rbenv-update.git ~/.rbenv/plugins/rbenv-update"
    )
    os.system(
        "git clone git://github.com/AndorChen/rbenv-china-mirror.git ~/.rbenv/plugins/rbenv-china-mirror"
    )

    path = os.path.expanduser("~")
    profile = path + "/" + ".profile"
    is_in_profile = file.is_in_file(profile, 'eval "$(rbenv init -)"')
    if False == is_in_profile:
        os.system("echo '' >> ~/.profile")
        os.system("echo export PATH='\"$HOME/.rbenv/bin:$PATH\"' >> ~/.profile")
        os.system("echo eval '\"$(rbenv init -)\"' >> ~/.profile")

    exit(0)
