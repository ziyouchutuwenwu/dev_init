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
    os.system(
        "echo 'apt update; apt-file update; apt upgrade -y; apt full-upgrade -y; apt autopurge -y; apt autoclean' > ~/.bash_history"
    )
    os.system("chattr +i ~/.bash_history")


def add_usr_sbin_to_path_env():
    os.environ["PATH"] += ":/usr/sbin/"


def set_apt_mirror(mirror_name):
    cmd = "echo  > /etc/apt/sources.list"
    os.system(cmd)
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "cp -rf %s/apt/%s.sources /etc/apt/sources.list.d/mirror.sources" % (
        current_dir,
        mirror_name,
    )
    os.system(cmd)


def add_chinese_support():
    os.system("ln -fs /usr/share/zoneinfo/Asia/Shanghai /etc/localtime")
    os.system("dpkg-reconfigure -f noninteractive tzdata")
    os.system("apt install locales -y")
    # 下面这几个顺序不能变
    os.system("sed -i -e 's/# zh_CN/zh_CN/g' /etc/locale.gen")
    os.system("dpkg-reconfigure -f noninteractive locales")
    # 影响的是 /etc/default/locale
    os.system("update-locale LANG=zh_CN.UTF-8")


def do_apt_update():
    os.system("apt update; apt upgrade -y; apt autoremove -y; apt autoclean")


def do_clean():
    os.system("apt autoremove -y; apt autoclean")


def add_apt_https_support():
    os.system("apt install -y apt-transport-https")


def install_build_tools():
    tool_list = ["build-essential", "autoconf"]
    for tool in tool_list:
        cmd = "apt install -y %s" % tool
        os.system(cmd)


def install_aptitude():
    os.system("apt install -y aptitude")


def init_profile():
    os.system("rm -rf ~/.profile")
    os.system("touch ~/.profile")


def install_apt_file():
    os.system("apt install -y apt-file")


def install_keepalived():
    os.system("apt install -y keepalived")


def install_gdebi():
    os.system("apt install -y gdebi")


def install_privoxy():
    os.system("apt install -y privoxy")
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "cp -rf %s/../../development/proxy/privoxy/config /etc/privoxy/config" % (
        current_dir
    )
    os.system(cmd)
    os.system("systemctl daemon-reload; systemctl enable privoxy")


def install_proxychains():
    os.system("apt install -y proxychains4")
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = (
        "cp -rf %s/../../development/proxy/proxychains/proxychains.conf /etc/proxychains4.conf"
        % (current_dir)
    )
    os.system(cmd)


def disable_sleep():
    cmd = "mkdir -p /etc/systemd/sleep.conf.d"
    os.system(cmd)
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "cp -rf %s/sleep/* /etc/systemd/sleep.conf.d/" % (current_dir)
    os.system(cmd)


def install_ansible_essential():
    os.system("apt install -y sshpass")


def install_netcat():
    os.system("apt install -y nmap ncat")
    os.system("update-alternatives --set nc /usr/bin/ncat")


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
        os.system(cmd)


def install_toys():
    os.system("apt install -y cmatrix cowsay")


def install_search_tools():
    os.system("apt install -y fd-find ripgrep")
    os.system("ln -s /usr/bin/fdfind /usr/bin/fd")


def install_encoding_tools():
    os.system("apt install -y enca")


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
        os.system(cmd)


def set_ntp():
    os.system("timedatectl set-ntp true")


def set_timezone():
    os.system("timedatectl set-timezone Asia/Shanghai")


def install_wifi_driver():
    os.system("apt install -y firmware-iwlwifi")


def install_zip_essential():
    os.system("apt install -y p7zip-full zip unzip unar rar unrar")


def install_ntfs_support():
    os.system("apt install -y ntfs-3g")


def set_global_profiles():
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "cp -rf %s/profile/*.sh /etc/profile.d/" % (current_dir)
    os.system(cmd)
    cmd = "mkdir -p /usr/local/etc/profile.d"
    os.system(cmd)
    cmd = "cp -rf %s/profile/profile.d/* /usr/local/etc/profile.d/" % (current_dir)
    os.system(cmd)


def set_swapping_config():
    cmd = "sysctl vm.swappiness=10"
    os.system(cmd)
    cmd = "echo vm.swappiness=10 > /etc/sysctl.d/swapping.conf"
    os.system(cmd)


def install_tmux():
    os.system("apt install -y tmux")
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "cp -rf %s/../../development/terminal/tmux/config/* /etc/" % (current_dir)
    os.system(cmd)


def set_fs_watches_config():
    cmd = "sysctl fs.inotify.max_user_watches=524288"
    os.system(cmd)
    cmd = "echo fs.inotify.max_user_watches=524288 > /etc/sysctl.d/fs_watches.conf"
    os.system(cmd)


def do_zsh_config():
    os.system("apt install -y zsh")
    os.system("usermod -s $(which zsh) root")
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "sh %s/zsh/global/config.sh" % (current_dir)
    os.system(cmd)
    cmd = "sh %s/zsh/root/config.sh" % (current_dir)
    os.system(cmd)


def install_ssh_server():
    os.system("apt install -y openssh-server")
    os.system(
        "sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config"
    )
    os.system(
        "sed -i 's/^#\\?GatewayPorts.*/GatewayPorts clientspecified/' /etc/ssh/sshd_config"
    )
    os.system("sed -i 's/^#X11Forwarding no/X11Forwarding yes/' /etc/ssh/sshd_config")
    os.system("systemctl restart ssh; systemctl enable ssh")


def remove_useless_applications():
    os.system("apt update")
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
        os.system(cmd)
    os.system("apt autoremove -y")


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
