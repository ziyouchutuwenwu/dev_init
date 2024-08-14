#!/usr/bin/env python
# -*- coding: UTF-8 -*-


import os
import sys


pwd = os.path.dirname(os.path.abspath(__file__))
module_path = "%s/../../" % pwd
sys.path.append(module_path)
from py_mods import proc


def disable_root_history():
    os.system("echo 'apt update; apt-file update; apt upgrade -y; apt full-upgrade -y; apt autopurge -y; apt autoclean' > ~/.bash_history")
    os.system("chattr +i ~/.bash_history")
    os.system("bash -cl 'history -c'")


def add_usr_sbin_to_path_env():
    os.environ["PATH"] += ":/usr/sbin/"


def set_mirror_apt_config(mirror_name):
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "cp -rf %s/apt/%s.list /etc/apt/sources.list" % (current_dir, mirror_name)
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
    os.system("apt update; apt upgrade -y; apt install -y build-essential; apt autoremove -y; apt autoclean")


def add_apt_https_support():
    os.system("apt install -y apt-transport-https")


def install_aptitude():
    os.system("apt install -y aptitude")


def install_apt_file():
    os.system("apt install -y apt-file")


def install_keepalived():
    os.system("apt install -y keepalived")


def install_gdebi():
    os.system("apt install -y gdebi")


def disable_sleep():
    cmd = "mkdir -p /etc/systemd/sleep.conf.d"
    os.system(cmd)
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "cp -rf %s/sleep/* /etc/systemd/sleep.conf.d/" % (current_dir)
    os.system(cmd)


def install_ansible_essential():
    os.system("apt install -y sshpass")


def install_net_tools():
    tool_list = ["sshfs", "nmap", "uml-utilities", "bridge-utils", "net-tools", "dnsutils", "tcptraceroute"]
    for tool in tool_list:
        cmd = "apt install -y %s" % tool
        os.system(cmd)


def install_toys():
    os.system("apt install -y cmatrix cowsay")


def install_useful_tools():
    tool_list = [
        "virt-what",
        "git",
        "rinetd",
        "screen",
        "dstat",
        "strace",
        "progress",
        "rename",
        "duf",
        "autossh",
        "catfish",
        "expect",
        "htop",
        "socat",
        "rsync",
        "neovim",
        "setserial",
        "genisoimage",
        "global",
        "tree",
        "silversearcher-ag",
        "wget",
        "curl",
        "aria2",
        "axel",
    ]
    for tool in tool_list:
        cmd = "apt install -y %s" % tool
        os.system(cmd)


def set_shang_hai_timezone():
    os.system("timedatectl set-timezone Asia/Shanghai")


def install_wifi_driver():
    os.system("apt install -y firmware-iwlwifi")


def install_zip_essential():
    os.system("apt install -y p7zip-full zip unzip unar rar unrar")


def install_ntfs_support():
    os.system("apt install -y ntfs-3g")


def set_global_profiles():
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "cp -rf %s/profile.d/* /etc/profile.d/" % (current_dir)
    os.system(cmd)


def set_swapping_config():
    cmd = "sysctl vm.swappiness=10"
    os.system(cmd)
    cmd = "echo vm.swappiness=10 > /etc/sysctl.d/swapping.conf"
    os.system(cmd)


def set_fs_watches_config():
    cmd = "sysctl fs.inotify.max_user_watches=524288"
    os.system(cmd)
    cmd = "echo fs.inotify.max_user_watches=524288 > /etc/sysctl.d/fs_watches.conf"
    os.system(cmd)


def install_ssh_server():
    os.system("apt install -y openssh-server")


def install_docker():
    os.system("mkdir -p /etc/apt/keyrings")
    os.system("curl -fsSL https://mirrors.ustc.edu.cn/docker-ce/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg")
    os.system('echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://mirrors.ustc.edu.cn/docker-ce/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null')
    os.system("apt update; apt install -y docker-ce")
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "cp -rf %s/docker/daemon.json /etc/docker/" % (current_dir)
    os.system(cmd)


def remove_useless_applications():
    os.system("apt update")
    app_list = [
        "xterm",
        "firefox*",
        "hv3",
        "imagemagic*",
        "epiphany-browser",
        "libreoffice*",
        "quodlibet",
        "goldendict",
        "exfalso",
        "xfburn",
        "xarchiver",
        "evince",
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
    if False == proc.is_root():
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
    set_global_profiles()
    set_swapping_config()
    set_fs_watches_config()
    set_mirror_apt_config(mirror_name)

    remove_useless_applications()

    do_apt_update()
    add_apt_https_support()

    install_aptitude()
    install_apt_file()
    install_keepalived()
    install_gdebi()
    add_chinese_support()
    install_net_tools()
    install_toys()
    install_ansible_essential()
    install_useful_tools()
    install_zip_essential()
    set_shang_hai_timezone()
    install_wifi_driver()
    install_ntfs_support()
    install_ssh_server()
    install_docker()
