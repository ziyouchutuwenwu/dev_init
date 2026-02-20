#!/usr/bin/env python
# -*- coding: UTF-8 -*-


import sys
import os
import subprocess

sys.dont_write_bytecode = True


def _is_in_file(file, content):
    reader = open(file)
    line = reader.readline()

    while line != "" and line is not None:
        if -1 != line.find(content):
            print(line)
            reader.close()
            return True
        line = reader.readline()
    reader.close()
    return False


def set_to_file(file, content, need_new_blank_line=False):
    is_existed = _is_in_file(file, content)
    if not is_existed:
        if need_new_blank_line:
            profile_cmd = "echo '' >> %s" % file
            subprocess.run(profile_cmd, shell=True)
        profile_cmd = "echo '%s' >> %s" % (content, file)
        subprocess.run(profile_cmd, shell=True)