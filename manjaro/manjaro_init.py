#!/usr/bin/env python
# -*- coding: UTF-8 -*-

from __future__ import print_function

import os
import sys

sys.path.append("..")
from py_mods import proc
from py_mods import file


def do_set_mirror_config():
    os.system("pacman-mirrors -i -c China -m rank")


def do_upgrade():
    os.system("pacman -Syyu --noconfirm")


def install_essential_fonts():
    os.system("pacman -S --noconfirm ttf-monaco")
    os.system("pacman -S --noconfirm ttf-roboto noto-fonts ttf-dejavu")
    os.system(
        "pacman -S --noconfirm wqy-bitmapfont wqy-microhei wqy-microhei-lite wqy-zenhei"
    )
    os.system(
        "pacman -S --noconfirm noto-fonts-cjk adobe-source-han-sans-cn-fonts adobe-source-han-serif-cn-fonts"
    )


def install_chinese_input():
    os.system("pacman -S --noconfirm fcitx-sunpinyin fcitx-im fcitx-configtool")
    os.system("cp ./xprofile_template ~/.xprofile")


def install_themes(user):
    proc.run_as_user(user, "mkdir -p ~/.themes")
    proc.run_as_user(user, "cp -rf ./themes/* ~/.themes")


def do_zprezto_config(user):
    os.system("pacman -S --noconfirm zsh")
    proc.run_as_user(user, "sh ./zprezto/config.sh")


def install_essential_tools():
    os.system("pacman -S --noconfirm vim git")


def set_linuxcn_package_setting():
    file_to_add_setting = "/etc/pacman.conf"
    content = "%s\n%s\n%s" % (
        "[archlinuxcn]",
        "SigLevel = Optional TrustedOnly",
        "Server =https://mirrors.ustc.edu.cn/archlinuxcn/$arch",
    )
    file.set_to_file(file_to_add_setting, content)

    os.system("pacman -Syy --noconfirm")
    os.system("pacman -S --noconfirm archlinuxcn-keyring")


if __name__ == "__main__":

    if False == proc.is_root():
        print("This program must be run as root. Aborting.")
        exit(-1)

    login_user = os.getlogin()

    do_set_mirror_config()
    do_upgrade()

    install_essential_tools()
    install_essential_fonts()
    install_chinese_input()
    install_themes(login_user)
    set_linuxcn_package_setting()

    # 太卡了，放最后
    do_zprezto_config(login_user)
