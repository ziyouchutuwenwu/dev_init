#!/usr/bin/env python
# -*- coding: UTF-8 -*-


import sys
sys.dont_write_bytecode = True

import os
import glob

pwd = os.path.dirname(os.path.abspath(__file__))
module_path = "%s/../../" % pwd
sys.path.append(module_path)
from py_mods import proc


def remove_useless():
    tools = [
        "firefox",
    ]
    for tool in tools:
        cmd = "xbps-remove -Ry %s" % tool
        os.system(cmd)


def set_mirror(mirror_name):
    os.system("mkdir -p /etc/xbps.d")
    os.system("cp /usr/share/xbps.d/*-repository-*.conf /etc/xbps.d/")
    current_dir = os.path.dirname(os.path.abspath(__file__))
    src = f"{current_dir}/mirror/{mirror_name}.conf"
    matches = glob.glob("/etc/xbps.d/*-repository-*.conf")
    if matches:
        dst = matches[0]
        os.system(f"cat {src} > {dst}")


def do_full_upgrade():
    os.system("xbps-install -Suy xbps")
    os.system("xbps-install -Suy")


def install_fonts():
    cmd = "xbps-install -y wqy-microhei"
    os.system(cmd)
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "cp -rf %s/fonts/* /usr/share/fonts/" % (current_dir)
    os.system(cmd)
    cmd = "xbps-reconfigure -f fontconfig"
    os.system(cmd)


def install_search_tools():
    os.system("xbps-install -y fd ripgrep")


def install_python_uv():
    os.system("xbps-install -y uv")


# nmap 自带的 nc 最强大
def install_nmap():
    os.system("xbps-install -y nmap")


def install_lts_kernel():
    os.system("xbps-install -y linux-lts")


def install_useful_tools():
    tools = [
        "neovim",
        "zellij",
        "git",
        "axel",
        "curl",
        "aria2",
        "htop",
        "autossh",
    ]
    for tool in tools:
        cmd = "xbps-install -y %s" % tool
        os.system(cmd)


def set_global_profiles():
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "cp -rf %s/profile/*.sh /etc/profile.d/" % (current_dir)
    os.system(cmd)
    cmd = "mkdir -p /usr/local/etc/profile.d"
    os.system(cmd)
    cmd = "cp -rf %s/profile/profile.d/* /usr/local/etc/profile.d/" % (current_dir)
    os.system(cmd)


def do_zsh_config():
    os.system("xbps-install -y zsh")
    os.system("usermod -s /usr/bin/zsh root")
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "sh %s/zsh/global/config.sh" % (current_dir)
    os.system(cmd)
    cmd = "sh %s/zsh/root/config.sh" % (current_dir)
    os.system(cmd)


if __name__ == "__main__":
    if False == proc.is_root():
        print("This program must be run as root. Aborting.")
        exit(-1)

    script_name = str(sys.argv[0])
    if len(sys.argv) < 2:
        print("用法: %s tuna" % (script_name))
        exit(-1)

    mirror_name = str(sys.argv[1])
    remove_useless()
    set_mirror(mirror_name)
    set_global_profiles()
    do_full_upgrade()
    install_lts_kernel()
    install_fonts()
    install_search_tools()
    install_useful_tools()
    install_nmap()
    install_python_uv()
    do_zsh_config()
