#!/usr/bin/env python
# -*- coding: UTF-8 -*-

from __future__ import print_function

import os
import sys

pwd = os.path.dirname(os.path.abspath(__file__))
module_path = "%s/../" % pwd
sys.path.append(module_path)
from py_mods import proc
from py_mods import file


def do_set_mirror_config():
    os.system("pacman-mirrors -i -c China -m rank")


def do_upgrade():
    os.system("pacman -Syyu --noconfirm")


def install_essential_fonts():
    os.system("pacman -S --noconfirm ttf-roboto noto-fonts ttf-dejavu")
    os.system(
        "pacman -S --noconfirm wqy-bitmapfont wqy-microhei wqy-microhei-lite wqy-zenhei"
    )
    os.system(
        "pacman -S --noconfirm noto-fonts-cjk adobe-source-han-sans-cn-fonts adobe-source-han-serif-cn-fonts"
    )


def install_chinese_input(user):
    os.system("pacman -S --noconfirm fcitx-im fcitx-configtool")
    os.system("pacman -S --noconfirm fcitx-libpinyin fcitx-cloudpinyin")
    proc.run_as_user(user, "cp -rf ./xprofile_template ~/.xprofile")


def install_themes(user):
    os.system("pacman -S --noconfirm numix-circle-icon-theme-git")
    proc.run_as_user(user, "mkdir -p ~/.themes")
    proc.run_as_user(user, "cp -rf ./themes/* ~/.themes")


def do_zprezto_config(user):
    os.system("pacman -S --noconfirm zsh")
    # 需要手动创建命令行，设置为目录的时候可见
    # terminator --working-directory=%f
    os.system("pacman -S --noconfirm terminator")
    proc.run_as_user(user, "chsh -s $(which zsh)")
    proc.run_as_user(user, "sh ./zprezto/config.sh")


def install_build_essential():
    os.system("pacman -S --noconfirm base-devel")


def install_erlang(user):
    os.system("pacman -S --noconfirm erlang rlwrap")
    proc.run_as_user(user, "echo \"alias erl='rlwrap -a erl'\" >> ~/.profile")


def install_useful_tools():
    os.system("pacman -S --noconfirm curl wget axel git ranger tree")


def remove_useless_applications():
    os.system("pacman -Rs --noconfirm mousepad thunderbird")


def install_proxychains(user):
    os.system("pacman -S --noconfirm proxychains-ng")
    proc.run_as_user(
        user,
        "echo \"alias proxy='proxychains'\" >> ~/.profile",
    )


def do_vim_config():
    os.system("pacman -S --noconfirm gvim")
    os.system("rm -rf /usr/share/applications/vim.desktop")


def install_yay():
    os.system("pacman -S --noconfirm yay")
    os.system('yay --aururl "https://aur.tuna.tsinghua.edu.cn" --save')


def set_linuxcn_pkg():
    setting_file = "/etc/pacman.conf"
    is_existed = file.is_in_file(setting_file, "[archlinuxcn]")
    if is_existed:
        return

    content = "%s\n%s\n%s" % (
        "[archlinuxcn]",
        "SigLevel = Optional TrustedOnly",
        "Server=https://mirrors.ustc.edu.cn/archlinuxcn/$arch",
    )
    file.set_to_file(setting_file, content)

    os.system("pacman -Syy --noconfirm")
    os.system("pacman -S --noconfirm archlinuxcn-keyring")


def install_monaco_fonts():
    os.system("pacman -S --noconfirm ttf-monaco")


if __name__ == "__main__":

    if False == proc.is_root():
        print("This program must be run as root. Aborting.")
        exit(-1)

    login_user = os.getlogin()

    do_set_mirror_config()
    do_upgrade()

    remove_useless_applications()

    install_build_essential()
    install_essential_fonts()
    install_erlang(login_user)
    install_proxychains(login_user)
    install_chinese_input(login_user)
    install_themes(login_user)
    do_vim_config()
    install_yay()

    # monaco字体需要linuxcn源
    set_linuxcn_pkg()
    install_monaco_fonts()
    install_useful_tools()

    # 太卡了，放最后
    do_zprezto_config(login_user)