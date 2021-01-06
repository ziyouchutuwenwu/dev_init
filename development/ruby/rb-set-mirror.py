#!/usr/bin/env python
# -*- coding: UTF-8 -*-

import os


def is_cmd_in_path(cmd):
    is_cmd_exist = False
    for cmdpath in os.environ["PATH"].split(":"):
        if os.path.isdir(cmdpath) and cmd in os.listdir(cmdpath):
            is_cmd_exist = True
            break
    return is_cmd_exist


if not is_cmd_in_path("gem"):
    print("please install ruby first")
    exit(-1)

os.system(
    "gem sources --add https://gems.ruby-china.com/ --remove https://rubygems.org/"
)
os.system("gem install bundle")
os.system("bundle config mirror.https://rubygems.org https://gems.ruby-china.com")
