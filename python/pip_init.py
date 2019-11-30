#!/usr/bin/env python
# -*- coding: UTF-8 -*-

import os
import sys

sys.path.append("..")
from py_mods import file

if __name__ == "__main__":

    cmd="pip install --upgrade pip"
    os.system(cmd)

    cmd="pip install virtualenv"
    os.system(cmd)

    cmd="pip install mycli"
    os.system(cmd)

    cmd="pip install pgcli"
    os.system(cmd)

    cmd="pip install you-get"
    os.system(cmd)

    cmd="pip install youtube-dl"
    os.system(cmd)

    cmd="pip install pyinotify"
    os.system(cmd)
    file.set_to_profile("alias pyfilemon=\"python -m pyinotify -v\"")
