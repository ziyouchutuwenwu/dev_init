#!/usr/bin/env python
# -*- coding: UTF-8 -*-


import sys

sys.dont_write_bytecode = True

import os

pwd = os.path.dirname(os.path.abspath(__file__))
module_path = "%s/../../" % pwd
sys.path.append(module_path)
from py_mods import proc


def disable_root_history():
    proc.run(
        "echo 'apt update; apt-file update; apt upgrade -y; apt full-upgrade -y; apt autopurge -y; apt autoclean' > ~/.bash_history"
    )
    proc.run("chattr +i ~/.bash_history")


def add_usr_sbin_to_path_env():
    os.environ["PATH"] += ":/usr/sbin/"


def set_apt_mirror(mirror_name):
    cmd = "echo  > /etc/apt/sources.list"
    proc.run(cmd)
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "cp -rf %s/apt/%s.sources /etc/apt/sources.list.d/mirror.sources" % (
        current_dir,
        mirror_name,
    )
    proc.run(cmd)


def add_chinese_support():
    proc.run("ln -fs /usr/share/zoneinfo/Asia/Shanghai /etc/localtime")
    proc.run("dpkg-reconfigure -f noninteractive tzdata")
    proc.run("apt install locales -y")
    # 下面这几个顺序不能变
    proc.run("sed -i -e 's/# zh_CN/zh_CN/g' /etc/locale.gen")
    proc.run("dpkg-reconfigure -f noninteractive locales")
    # 影响的是 /etc/default/locale
    proc.run("update-locale LANG=zh_CN.UTF-8")


def do_apt_update():
    proc.run("apt update; apt upgrade -y; apt autoremove -y; apt autoclean")


def do_clean():
    proc.run("apt autoremove -y; apt autoclean")


def add_apt_https_support():
    proc.run("apt install -y apt-transport-https")


def install_build_tools():
    tool_list = ["build-essential", "autoconf"]
    for tool in tool_list:
        cmd = "apt install -y %s" % tool
        proc.run(cmd)


def install_aptitude():
    proc.run("apt install -y aptitude")


def init_profile():
    proc.run("rm -rf ~/.profile")
    proc.run("touch ~/.profile")


def install_apt_file():
    proc.run("apt install -y apt-file")


def install_keepalived():
    proc.run("apt install -y keepalived")


def install_gdebi():
    proc.run("apt install -y gdebi")


def install_privoxy():
    proc.run("apt install -y privoxy")
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "cp -rf %s/../../development/proxy/privoxy/config /etc/privoxy/config" % (
        current_dir
    )
    proc.run(cmd)
    proc.run("systemctl daemon-reload; systemctl enable privoxy")


def install_proxychains():
    proc.run("apt install -y proxychains4")
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = (
        "cp -rf %s/../../development/proxy/proxychains/proxychains.conf /etc/proxychains4.conf"
        % (current_dir)
    )
    proc.run(cmd)


def disable_sleep():
    cmd = "mkdir -p /etc/systemd/sleep.conf.d"
    proc.run(cmd)
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "cp -rf %s/sleep/* /etc/systemd/sleep.conf.d/" % (current_dir)
    proc.run(cmd)


def install_ansible_essential():
    proc.run("apt install -y sshpass")


def install_netcat():
    proc.run("apt install -y nmap ncat")
    proc.run("update-alternatives --set nc /usr/bin/ncat")


def install_net_tools():
    tool_list = [
        "whois",
        "cifs-utilssshfs",
        "uml-utilities",
        "bridge-utils",
        "net-tools",
        "dnsutils",
        "tcptraceroute",
    ]
    for tool in tool_list:
        cmd = "apt install -y %s" % tool
        proc.run(cmd)


def install_toys():
    proc.run("apt install -y cmatrix cowsay")


def install_search_tools():
    proc.run("apt install -y fd-find ripgrep")
    proc.run("ln -s /usr/bin/fdfind /usr/bin/fd")


def install_encoding_tools():
    proc.run("apt install -y enca")


def install_useful_tools():
    tool_list = [
        "reptyr",
        "binaryen",
        "virt-what",
        "git",
        "fastfetch",
        "screen",
        "dstat",
        "strace",
        "progress",
        "rename",
        "duf",
        "autossh",
        "expect",
        "htop",
        "socat",
        "rsync",
        "neovim",
        "setserial",
        "genisoimage",
        "global",
        "tree",
        "wget",
        "curl",
        "aria2",
        "axel",
    ]
    for tool in tool_list:
        cmd = "apt install -y %s" % tool
        proc.run(cmd)


def set_ntp():
    proc.run("timedatectl set-ntp true")


def set_timezone():
    proc.run("timedatectl set-timezone Asia/Shanghai")


def install_wifi_driver():
    proc.run("apt install -y firmware-iwlwifi")


def install_zip_essential():
    proc.run("apt install -y p7zip-full zip unzip unar rar unrar")


def install_ntfs_support():
    proc.run("apt install -y ntfs-3g")


def set_global_profiles():
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "cp -rf %s/profile/*.sh /etc/profile.d/" % (current_dir)
    proc.run(cmd)
    cmd = "mkdir -p /usr/local/etc/profile.d"
    proc.run(cmd)
    cmd = "cp -rf %s/profile/profile.d/* /usr/local/etc/profile.d/" % (current_dir)
    proc.run(cmd)


def set_swapping_config():
    cmd = "sysctl vm.swappiness=10"
    proc.run(cmd)
    cmd = "echo vm.swappiness=10 > /etc/sysctl.d/swapping.conf"
    proc.run(cmd)


def install_tmux():
    proc.run("apt install -y tmux")
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "cp -rf %s/../../development/terminal/tmux/config/* /etc/" % (current_dir)
    proc.run(cmd)


def set_fs_watches_config():
    cmd = "sysctl fs.inotify.max_user_watches=524288"
    proc.run(cmd)
    cmd = "echo fs.inotify.max_user_watches=524288 > /etc/sysctl.d/fs_watches.conf"
    proc.run(cmd)


def do_zsh_config():
    proc.run("apt install -y zsh")
    proc.run("usermod -s $(which zsh) root")
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "sh %s/zsh/global/config.sh" % (current_dir)
    proc.run(cmd)
    cmd = "sh %s/zsh/root/config.sh" % (current_dir)
    proc.run(cmd)


def install_ssh_server():
    proc.run("apt install -y openssh-server")
    proc.run(
        "sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config"
    )
    proc.run(
        "sed -i 's/^#\\?GatewayPorts.*/GatewayPorts clientspecified/' /etc/ssh/sshd_config"
    )
    proc.run("sed -i 's/^#X11Forwarding no/X11Forwarding yes/' /etc/ssh/sshd_config")
    proc.run("systemctl restart ssh; systemctl enable ssh")


def remove_useless_applications():
    proc.run("apt update")
    app_list = [
        "xterm",
        "firefox*",
        "imagemagic*",
        "libreoffice*",
        "quodlibet",
        "light-locker",
        "netcat-traditional",
        "exfalso",
        "xfburn",
        "nautilus",
        "xsane*",
        "mousepad",
        "vim-common",
        "atril",
        "linux-image-$(dpkg --print-architecture)",
    ]
    for app in app_list:
        cmd = "apt purge -y %s" % app
        proc.run(cmd)
    proc.run("apt autoremove -y")


if __name__ == "__main__":
    if not proc.is_root():
        print("This program must be run as root. Aborting.")
        exit(-1)

    script_name = str(sys.argv[0])
    if len(sys.argv) < 2:
        print("用法: %s aliyun/ustc" % (script_name))
        exit(-1)

    mirror_name = str(sys.argv[1])
    add_usr_sbin_to_path_env()
    disable_sleep()
    disable_root_history()
    init_profile()
    set_global_profiles()
    set_swapping_config()
    set_fs_watches_config()
    set_apt_mirror(mirror_name)

    remove_useless_applications()

    set_ntp()
    set_timezone()
    do_apt_update()
    add_apt_https_support()

    install_aptitude()
    install_apt_file()
    install_build_tools()
    install_keepalived()
    install_gdebi()
    add_chinese_support()
    install_encoding_tools()
    install_toys()
    install_net_tools()
    install_netcat()
    install_tmux()
    install_privoxy()
    install_proxychains()
    install_ansible_essential()
    install_useful_tools()
    install_search_tools()
    install_zip_essential()
    install_wifi_driver()
    install_ntfs_support()
    install_ssh_server()
    do_zsh_config()
    do_clean()
