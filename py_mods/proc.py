#!/usr/bin/env python
# -*- coding: UTF-8 -*-


import sys
sys.dont_write_bytecode = True

import os
import subprocess


def exec_cmd_with_result_list(cmd):
    res = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, close_fds=True)
    result = res.stdout.readlines()
    return result


def run_as_user(user, cmd):
    subprocess.call(["su", user, "-c", cmd])


def is_root():
    if os.geteuid() != 0:
        return False
    return True
