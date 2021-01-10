#!/usr/bin/env python

from __future__ import print_function

import os
import sys

pwd = os.path.split(os.path.realpath(__file__))[0]
module_path = "%s/../../" % pwd
sys.path.append(module_path)
from py_mods import proc

def convert_result_to_version(result):
    str_result = (" ".join("%s" % id for id in result)).rstrip("\\n'")
    str_val = str_result.split(" ")[-1]
    return float(str_val)


if __name__ == "__main__":
    pkaction_result = proc.exec_cmd_with_result_list("pkaction --version")
    pkaction_version = convert_result_to_version(pkaction_result)

    if pkaction_version * 10000 >= 0.106 * 10000:
        os.system("mkdir -p /etc/polkit-1/rules.d")
        cmd = "cp %s/85-hibernate.rules /etc/polkit-1/rules.d/" % pwd
        os.system(cmd)
    else:
        cmd = (
            "cp %s/20-allow-hibernate.pkla /etc/polkit-1/localauthority/50-local.d/"
            % pwd
        )
        os.system(cmd)
