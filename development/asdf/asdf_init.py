#!/usr/bin/env python
# -*- coding: UTF-8 -*-

from __future__ import print_function

import os
import sys


pwd = os.path.dirname(os.path.abspath(__file__))
module_path = "%s/../../" % pwd
sys.path.append(module_path)
from py_mods import file


if __name__ == "__main__":
    os.system("git clone --depth 1 https://github.com/asdf-vm/asdf.git ~/.asdf")

    path = os.path.expanduser("~")
    profile = path + "/" + ".profile"
    file.set_to_file(profile, 'export PYTHON_BUILD_MIRROR_URL_SKIP_CHECKSUM=1', need_new_blank_line=True)
    file.set_to_file(profile, 'export PYTHON_BUILD_MIRROR_URL="https://npm.taobao.org/mirrors/python/"')
    file.set_to_file(profile, "source $HOME/.asdf/asdf.sh", need_new_blank_line=True)
    os.system("bash -c 'source $HOME/.asdf/asdf.sh; asdf update'")
