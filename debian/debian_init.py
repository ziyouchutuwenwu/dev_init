#!/usr/bin/env python
# -*- coding: UTF-8 -*-

from __future__ import print_function

import os
import sys

sys.path.append("..")
from py_mods import proc

def add_usr_sbin_to_path_env():
    os.environ["PATH"] += ":/usr/sbin/"

def do_apt_update():
    os.system(
        "apt update -y; apt upgrade -y; apt install build-essential -y; apt autoremove -y; apt autoclean")

def set_tsinghua_apt_config():
    os.system("cp ./apt/tsinghua.list /etc/apt/sources.list")

def set_aliyun_apt_config():
    os.system("cp ./apt/aliyun.list /etc/apt/sources.list")

def add_apt_https_support():
    os.system("apt install apt-transport-https -y")

def install_sudo(user):
    os.system("apt install sudo -y")
    cmd = "gpasswd -a %s sudo" % user
    os.system(cmd)

def install_doc():
    os.system("apt install zeal -y")

def install_audio_manager():
    os.system("apt install pulseaudio -y")

def install_bt_client():
    os.system("apt install qbittorrent -y")

def install_ntfs_support():
    os.system("apt install ntfs-3g -y")

def rm_unused_menu(user):
    proc.run_as_user(user, "rm -rf ~/.local/share/applications/*.wine")

def install_embedded_tools():
    os.system("apt install u-boot-tools qemu-system-arm -y")
    os.system("apt install i2c-tools spi-tools can-utils -y")
    os.system("apt install gdb gdbserver gdb-multiarch -y")
    os.system("apt install gcc-arm-linux-gnueabi gcc-arm-none-eabi gcc-arm-linux-gnueabihf -y")
    os.system("apt install mtd-utils -y")

def install_wireshark(user):
    os.system("apt install wireshark -y")
    cmd = "usermod -a -G wireshark %s" % user
    os.system(cmd)

def install_power_management_tool(user):
    os.system("apt install tlp -y")
    proc.run_as_user(user, "sh ./enable_hibernate/config.sh")

def install_fonts():
    os.system("apt install fonts-droid-fallback -y")

def install_theme():
    os.system("apt install faenza-icon-theme -y")

def install_serial_tools():
    os.system("apt install picocom lrzsz -y")
    os.system("cp ./peripheral_permission/* /etc/udev/rules.d/")

def install_chinese():
    os.system("apt install xfonts-intl-chinese fonts-wqy-microhei fonts-wqy-zenhei xfonts-wqy -y")
    os.system("apt install fcitx fcitx-sunpinyin fcitx-module-cloudpinyin -y")
    os.system("dpkg-reconfigure locales")

def set_shang_hai_timezone():
    os.system("timedatectl set-timezone Asia/Shanghai")

def install_image_reader():
    os.system("apt install ristretto -y")

def install_wifi_driver():
    os.system("apt install firmware-iwlwifi -y")

def make_xfce_ftp_support():
    os.system("apt install gvfs-backends -y")

def install_gdebi():
    os.system("apt install gdebi -y")

def install_useful_tools():
    os.system("apt install rdesktop tree vim git wget curl axel galculator xfce4-screenshooter screenfetch gufw htop psensor -y")

def install_net_tools():
    os.system("apt install uml-utilities bridge-utils net-tools -y")

def install_gz_to_deb():
    os.system("apt install java-package -y")

def install_mail_client():
    os.system("apt install sylpheed -y")

def install_file_search_tool():
    os.system("apt install catfish -y")

def install_clipboard_tool():
    os.system("apt install xfce4-clipman xfce4-clipman-plugin -y")

def install_notes_tool():
    os.system("apt install gnote -y")

def install_gantt_chart_tool():
    os.system("apt install planner -y")

def install_chm_reader():
    os.system("apt install xchm -y")

def install_pdf_reader():
    os.system("apt install qpdfview qpdfview-translations -y")

def install_flow_chart_tool():
    os.system("apt install dia -y")

def install_disk_partition_tool():
    os.system("apt install gparted -y")

def install_zip_tool(user):
    os.system("apt install engrampa p7zip-full zip unzip rar unrar -y")

    proc.run_as_user(user, "rm -rf ~/.local/share/recently-used.xbel")
    proc.run_as_user(user, "mkdir -p ~/.local/share/recently-used.xbel/")

def remove_useless_applications():
    os.system("apt purge tumbler libreoffice* xfburn evince sane* mousepad -y")
    os.system("apt autoremove -y")
    os.system("apt install xfce4-taskmanager -y")

def add_monaco_font():
    os.system("mkdir -p /usr/share/fonts/truetype/custom")
    os.system("cp ./fonts/* /usr/share/fonts/truetype/custom")
    os.system("fc-cache -f -v")

def set_xterm_config(user):
    proc.run_as_user(user, "cp -rf ./xterm_config/default.conf ~/.Xdefaults")

def install_erlang(user):
    os.system("apt install erlang rlwrap -y")
    proc.run_as_user(user, "echo \"alias erl='rlwrap -a erl'\" >> ~/.profile")

def install_docker(user):
    os.system("apt install software-properties-common -y")
    os.system("curl -fsSL https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/debian/gpg | apt-key add -")
    os.system("add-apt-repository \"deb [arch=amd64] https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/debian $(lsb_release -cs) stable\"")
    os.system("apt update; apt install docker-ce -y")
    cmd = "usermod -a -G docker %s" % user
    os.system(cmd)
    os.system("cp -rf ./docker/daemon.json /etc/docker/daemon.json")

def install_k8s():
    os.system("curl https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | apt-key add - ")
    os.system("echo deb https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main > /etc/apt/sources.list.d/kubernetes.list")
    os.system("apt update; apt install kubelet kubeadm kubectl -y")
    # k8s的包管理工具
    # os.system("curl -sSL https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | bash")

def install_themes(user):
    proc.run_as_user(user, "mkdir -p ~/.themes")
    proc.run_as_user(user, "cp -rf ./themes/* ~/.themes")

def set_profile(user):
    proc.run_as_user(user, "echo \"alias open_extra_menu='thunar ~/.local/share/applications'\" > ~/.profile")
    # ip
    proc.run_as_user(user, "echo \"\nalias proxy='export http_proxy=socks5://127.0.0.1:1080 https_proxy=socks5://127.0.0.1:1080 all_proxy=socks5://127.0.0.1:1080'\" >> ~/.profile")
    proc.run_as_user(user, "echo \"alias unproxy='unset http_proxy https_proxy all_proxy'\" >> ~/.profile")
    proc.run_as_user(user, "echo \"alias get_ip='curl -i http://ipinfo.io/json'\" >> ~/.profile")

    proc.run_as_user(user, "echo \"\nalias binwalk='docker run --rm --name binwalk -v \"$(pwd)\":/binwalk rjocoleman/binwalk'\" >> ~/.profile")

def do_zprezto_config(user):
    os.system("apt install zsh -y")
    proc.run_as_user(user, "sh ./zprezto/config.sh")

def do_install_xfce_terminal_themes(user):
    proc.run_as_user(user, "sh ./terminal_theme/install.sh")

def do_vim_config(user):
    os.system("apt install vim -y")
    proc.run_as_user(user, "sh ./vim/install.sh")

def fix_translation_bug():
    os.system("./bug_fix/i18n_fix.sh")

if __name__ == "__main__":

    add_usr_sbin_to_path_env()

    if False == proc.is_root():
        print("This program must be run as root. Aborting.")
        exit(-1)

    login_user = os.getlogin()
    set_xterm_config(login_user)

    set_aliyun_apt_config()
    do_apt_update()

    add_apt_https_support()
    install_sudo(login_user)

    # 需要确认的放前面，减少用户等待的时间
    install_chinese()
    install_wireshark(login_user)

    install_gdebi()
    install_net_tools()
    install_useful_tools()
    install_serial_tools()
    install_gz_to_deb()
    install_theme()
    install_fonts()
    set_shang_hai_timezone()
    install_doc()
    install_power_management_tool(login_user)
    install_audio_manager()
    install_embedded_tools()
    install_bt_client()
    install_image_reader()
    install_wifi_driver()
    install_flow_chart_tool()
    install_disk_partition_tool()
    install_zip_tool(login_user)
    install_file_search_tool()
    install_clipboard_tool()
    install_notes_tool()
    install_pdf_reader()
    install_chm_reader()
    install_gantt_chart_tool()
    install_ntfs_support()
    install_mail_client()

    add_monaco_font()
    make_xfce_ftp_support()

    remove_useless_applications()

    rm_unused_menu(login_user)
    install_themes(login_user)
    do_install_xfce_terminal_themes(login_user)

    # 这个必须在zprezto之前配置
    set_profile(login_user)
    do_vim_config(login_user)

    install_erlang(login_user)
    install_docker(login_user)

    install_k8s()
    fix_translation_bug()

    # 太卡了，放最后
    do_zprezto_config(login_user)