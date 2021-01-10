#!/usr/bin/env python
# -*- coding: UTF-8 -*-

import os
import sys

pwd = os.path.dirname(os.path.abspath(__file__))
module_path = "%s/../../" % pwd
sys.path.append(module_path)
from py_mods import file

if __name__ == "__main__":

    cmd = "pip install --upgrade pip"
    os.system(cmd)

    cmd = "pip install virtualenv --upgrade"
    os.system(cmd)

    # pip-review --auto
    cmd = "pip install pip-review --upgrade"
    os.system(cmd)

    cmd = "pip install stegoveritas-binwalk --upgrade"
    os.system(cmd)

    # beckhoff的通信库
    cmd = "pip install pyads --upgrade"
    os.system(cmd)

    # vscode 代码格式化工具
    cmd = "pip install black --upgrade"
    os.system(cmd)

    # vscode 代码错误检查工具
    cmd = "pip install pylint --upgrade"
    os.system(cmd)

    cmd = "pip install sqlmap --upgrade"
    os.system(cmd)

    cmd = "pip install pysocks --upgrade"
    os.system(cmd)

    cmd = "pip install pyqt5 PyQtWebEngine --upgrade"
    os.system(cmd)

    cmd = "pip install requests --upgrade"
    os.system(cmd)

    cmd = "pip install selenium --upgrade"
    os.system(cmd)

    cmd = "pip install httpie --upgrade"
    os.system(cmd)

    cmd = "pip install scons --upgrade"
    os.system(cmd)

    cmd = "pip install docker-compose --upgrade"
    os.system(cmd)

    cmd = "pip install you-get --upgrade"
    os.system(cmd)

    cmd = "pip install youtube-dl --upgrade"
    os.system(cmd)

    cmd = "pip install mkdocs sphinx-rtd-theme --upgrade"
    os.system(cmd)

    cmd = "pip install beautifulsoup4 --upgrade"
    os.system(cmd)

    cmd = "pip install pyinotify --upgrade"
    os.system(cmd)
    path = os.path.expanduser("~")
    profile = path + "/" + ".profile"
    file.set_to_file(profile, 'alias pyfilemon="python -m pyinotify -v"')

    # github.com/rohanrhu/gdb-frontend
    cmd = "pip install gdbfrontend --upgrade"
    os.system(cmd)

    # pip search目前有问题，需要使用下面这个, 命令是 pip_search
    cmd = "pip install pip-search --upgrade"
    os.system(cmd)