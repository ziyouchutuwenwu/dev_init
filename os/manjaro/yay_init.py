#!/usr/bin/env python
# -*- coding: UTF-8 -*-


import sys

sys.dont_write_bytecode = True

import os

pwd = os.path.dirname(os.path.abspath(__file__))
module_path = "%s/../../" % pwd
sys.path.append(module_path)
from py_mods import file, proc


def update_sudo_passwd_template(pwd):
    sudo_passwd_template = "/tmp/pass.sh"
    os.system("rm -rf %s" % sudo_passwd_template)
    os.system("touch %s" % sudo_passwd_template)
    os.system("chmod a+x %s" % sudo_passwd_template)
    file.set_to_file(sudo_passwd_template, "'#! /bin/bash'")
    file.set_to_file(sudo_passwd_template, "echo %s" % pwd)


def remove_sudo_passwd_template():
    sudo_passwd_template = "/tmp/pass.sh"
    os.system("rm -rf %s" % sudo_passwd_template)


def init_yay(user):
    os.system("yes | pacman --noconfirm -S yay")
    sudo_ask_pass_info = "export SUDO_ASKPASS=/tmp/pass.sh"
    install_cmd = "yay --sudoloop --save"
    cmd = "%s; %s" % (sudo_ask_pass_info, install_cmd)
    proc.run_as_user(user, cmd)


def install_themes(user):
    sudo_ask_pass_info = "export SUDO_ASKPASS=/tmp/pass.sh"
    install_cmd = "yes | yay --noconfirm -S --sudoflags -A faenza-icon-theme"
    cmd = "%s; %s" % (sudo_ask_pass_info, install_cmd)
    proc.run_as_user(user, cmd)
    proc.run_as_user(user, "mkdir -p ~/.themes")
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "cp -rf %s/themes/* ~/.themes" % (current_dir)
    proc.run_as_user(user, cmd)


def install_pdf_viewer(user):
    sudo_ask_pass_info = "export SUDO_ASKPASS=/tmp/pass.sh"
    install_cmd = "yes | yay --noconfirm -S --sudoflags -A qpdfview"
    cmd = "%s; %s" % (sudo_ask_pass_info, install_cmd)
    proc.run_as_user(user, cmd)
    os.system("yes | pacman --noconfirm -Rcns qt5-tools")


def install_browser(user):
    sudo_ask_pass_info = "export SUDO_ASKPASS=/tmp/pass.sh"
    install_cmd = "yes | yay --noconfirm -S --sudoflags -A google-chrome"
    cmd = "%s; %s" % (sudo_ask_pass_info, install_cmd)
    proc.run_as_user(user, cmd)


def install_virt_manager_extra(user):
    sudo_ask_pass_info = "export SUDO_ASKPASS=/tmp/pass.sh"
    # virt-manager 的 win10 剪贴板驱动
    install_cmd = "yes | yay --noconfirm -S --sudoflags -A spice-guest-tools-windows"
    cmd = "%s; %s" % (sudo_ask_pass_info, install_cmd)
    proc.run_as_user(user, cmd)
    # win7 需要这个才能安装
    install_cmd = "yes | yay --noconfirm -S --sudoflags -A virtio-win"
    cmd = "%s; %s" % (sudo_ask_pass_info, install_cmd)
    proc.run_as_user(user, cmd)


def install_wps(user):
    sudo_ask_pass_info = "export SUDO_ASKPASS=/tmp/pass.sh"
    install_cmd = "yes | yay --noconfirm -S --sudoflags -A wps-office-cn ttf-wps-fonts"
    cmd = "%s; %s" % (sudo_ask_pass_info, install_cmd)
    proc.run_as_user(user, cmd)
    install_cmd = "yes | yay --noconfirm -S --sudoflags -A wps-office-mui-zh-cn"
    cmd = "%s; %s" % (sudo_ask_pass_info, install_cmd)
    proc.run_as_user(user, cmd)


if __name__ == "__main__":
    if not proc.is_root():
        print("This program must be run as root. Aborting.")
        exit(-1)

    script_name = str(sys.argv[0])
    login_user = os.getlogin()
    if len(sys.argv) < 2:
        print("用法: %s %s的密码" % (script_name, login_user))
        exit(-1)

    login_pwd = str(sys.argv[1])

    update_sudo_passwd_template(login_pwd)

    init_yay(login_user)
    install_themes(login_user)
    install_browser(login_user)
    install_pdf_viewer(login_user)
    install_wps(login_user)
    install_virt_manager_extra(login_user)

    remove_sudo_passwd_template()
