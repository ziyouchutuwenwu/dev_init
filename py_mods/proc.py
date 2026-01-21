#!/usr/bin/env python
# -*- coding: UTF-8 -*-


import os
import subprocess
import sys

sys.dont_write_bytecode = True


def run_as_user(user, cmd):
    subprocess.call(["su", user, "-c", cmd])


def is_root():
    if os.geteuid() != 0:
        return False
    return True
