#!/usr/bin/env python
# -*- coding: UTF-8 -*-

from __future__ import print_function
import os


def is_in_file(file, content):
    reader = open(file)
    line = reader.readline()

    while line != "" and line != None:
        if -1 != line.find(content):
            print(line)
            reader.close()
            return True
        line = reader.readline()
    reader.close()
    return False


def set_to_file(file, content, need_new_blank_line=False):
    is_existed = is_in_file(file, content)
    if False == is_existed:
        if need_new_blank_line == True:
            profile_cmd = "echo '' >> %s" % file
            os.system(profile_cmd)
        profile_cmd = "echo '%s' >> %s" % (content, file)
        os.system(profile_cmd)
