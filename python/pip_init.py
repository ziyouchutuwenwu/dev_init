#!/usr/bin/env python
# -*- coding: UTF-8 -*-

import os
import sys

sys.path.append("..")
from py_mods import file
from py_mods import proc

def get_adb_path_through_airtest():
    adb_path: str = ""
    results = proc.exec_cmd_with_result_list("find ~/.pyenv -name 'adb' | grep linux/")
    for result in results:
        info = str(result, 'utf-8')
        if info.find("/linux/") != -1:
            adb_path = info.replace(os.environ['HOME'], "~")
            break
    return adb_path

if __name__ == "__main__":

    cmd="pip install --upgrade pip"
    os.system(cmd)

    cmd="pip install you-get"
    os.system(cmd)

    cmd="pip install youtube-dl"
    os.system(cmd)

    cmd="pip install flawfinder"
    os.system(cmd)

    cmd="pip install pocoui"
    os.system(cmd)
    adb_cmd = get_adb_path_through_airtest()
    cmd="chmod +x %s" % adb_cmd
    os.system(cmd)
    adb_path = adb_cmd[:adb_cmd.rfind("/")]
    new_sys_path = "export PATH=%s:$PATH" % adb_path
    file.set_to_profile(new_sys_path)

    cmd="pip install pyinotify"
    os.system(cmd)
    file.set_to_profile("alias pyfilemon=\"python -m pyinotify -v\"")

    cmd="pip install binwalk"
    os.system(cmd)