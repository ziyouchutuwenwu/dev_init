#!/usr/bin/env python
# -*- coding: UTF-8 -*-


import sys

sys.dont_write_bytecode = True

import glob
import os

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
        proc.run(cmd)


def set_mirror(mirror_name):
    proc.run("mkdir -p /etc/xbps.d")
    proc.run("cp /usr/share/xbps.d/*-repository-*.conf /etc/xbps.d/")
    current_dir = os.path.dirname(os.path.abspath(__file__))
    src = f"{current_dir}/mirror/{mirror_name}.conf"
    matches = glob.glob("/etc/xbps.d/*-repository-*.conf")
    if matches:
        dst = matches[0]
        proc.run(f"cat {src} > {dst}")


def do_full_upgrade():
    proc.run("xbps-install -Suy xbps")
    proc.run("xbps-install -Suy")


def config_ssh_server():
    proc.run(
        "sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config"
    )
    proc.run(
        "sed -i 's/^#\\?GatewayPorts.*/GatewayPorts clientspecified/' /etc/ssh/sshd_config"
    )
    proc.run("sed -i 's/^#X11Forwarding no/X11Forwarding yes/' /etc/ssh/sshd_config")
    proc.run("sv restart sshd")


def do_clean():
    proc.run("xbps-remove -Ooy")


def install_fonts():
    cmd = "xbps-install -y wqy-microhei"
    proc.run(cmd)
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "cp -rf %s/fonts/* /usr/share/fonts/" % (current_dir)
    proc.run(cmd)
    cmd = "xbps-reconfigure -f fontconfig"
    proc.run(cmd)


def install_search_tools():
    proc.run("xbps-install -y fd ripgrep")


def install_python_uv():
    proc.run("xbps-install -y uv")


# nmap 自带的 nc 最强大
def install_nmap():
    proc.run("xbps-install -y nmap")


def install_kernel():
    proc.run("xbps-install -y linux-lts")


def install_tmux():
    proc.run("xbps-install -y tmux")
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "cp -rf %s/../../development/terminal/tmux/config/* /etc/" % (current_dir)
    proc.run(cmd)


def install_vim():
    proc.run("xbps-install -y neovim")


def install_useful_tools():
    tools = [
        "reptyr",
        "rsync",
        "fastfetch",
        "tree",
        "git",
        "axel",
        "curl",
        "aria2",
        "htop",
        "net-tools",
        "bind-utils",
        "autossh",
    ]
    for tool in tools:
        cmd = "xbps-install -y %s" % tool
        proc.run(cmd)


def install_ssh_esential():
    proc.run("xbps-install -y autossh fuse-sshfs")


def install_zip_essential():
    proc.run("xbps-install -y xz unzip unrar")


def set_sudo_timeout():
    proc.run(
        "echo 'Defaults timestamp_timeout=30' | tee /etc/sudoers.d/global-timeout > /dev/null"
    )


def install_privoxy():
    proc.run("xbps-install -y privoxy")
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "cp -rf %s/../../development/proxy/privoxy/config /etc/privoxy/config" % (
        current_dir
    )
    proc.run(cmd)
    proc.run("ln -s /etc/sv/privoxy /var/service/")


def install_proxychains():
    proc.run("xbps-install -y proxychains-ng")
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = (
        "cp -rf %s/../../development/proxy/proxychains/proxychains.conf /etc/proxychains.conf"
        % (current_dir)
    )
    proc.run(cmd)


def set_global_profiles():
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "cp -rf %s/profile/*.sh /etc/profile.d/" % (current_dir)
    proc.run(cmd)
    cmd = "mkdir -p /usr/local/etc/profile.d"
    proc.run(cmd)
    cmd = "cp -rf %s/profile/profile.d/* /usr/local/etc/profile.d/" % (current_dir)
    proc.run(cmd)


def do_zsh_config():
    proc.run("xbps-install -y zsh")
    proc.run("usermod -s /usr/bin/zsh root")
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "sh %s/zsh/global/config.sh" % (current_dir)
    proc.run(cmd)
    cmd = "sh %s/zsh/root/config.sh" % (current_dir)
    proc.run(cmd)


if __name__ == "__main__":
    if not proc.is_root():
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
    config_ssh_server()
    install_kernel()
    install_fonts()
    install_ssh_esential()
    install_tmux()
    install_privoxy()
    install_proxychains()
    install_vim()
    set_sudo_timeout()
    install_search_tools()
    install_useful_tools()
    install_zip_essential()
    install_nmap()
    install_python_uv()
    do_zsh_config()
    do_clean()
