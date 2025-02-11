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
    path = os.path.expanduser("~")
    profile = path + "/" + ".profile"
    file.set_to_file(profile, 'export ASDF_DATA_DIR="$HOME/.asdf"', need_new_blank_line=True)
    file.set_to_file(profile, 'export PATH="$ASDF_DATA_DIR/shims:$PATH"')