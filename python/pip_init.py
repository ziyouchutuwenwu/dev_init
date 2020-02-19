#!/usr/bin/env python
# -*- coding: UTF-8 -*-

import os
import sys

sys.path.append("..")
from py_mods import file

if __name__ == "__main__":

    cmd="pip install --upgrade pip"
    os.system(cmd)

    cmd="pip install sqlmap"
    os.system(cmd)

    cmd="pip install pysocks"
    os.system(cmd)

    cmd="pip install pyqt5 PyQtWebEngine"
    os.system(cmd)

    cmd="pip install requsts"
    os.system(cmd)

    cmd="pip install mycli"
    os.system(cmd)

    cmd="pip install pgcli"
    os.system(cmd)

    cmd="pip install httpie"
    os.system(cmd)

    cmd="pip install pip-review"
    os.system(cmd)

    cmd="pip install you-get"
    os.system(cmd)

    cmd="pip install youtube-dl"
    os.system(cmd)

    cmd="pip install pyinotify"
    os.system(cmd)
    file.set_to_profile("alias pyfilemon=\"python -m pyinotify -v\"")
