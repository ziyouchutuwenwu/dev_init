#!/usr/bin/env python
# -*- coding: UTF-8 -*-

from __future__ import print_function

import os
import sys

pwd = os.path.split(os.path.realpath(__file__))[0]
module_path = "%s/../" % pwd
sys.path.append(module_path)
from py_mods import proc


def add_usr_sbin_to_path_env():
    os.environ["PATH"] += ":/usr/sbin/"


def do_apt_update():
    os.system(
        "apt update -y; apt upgrade -y; apt install build-essential -y; apt autoremove -y; apt autoclean"
    )


def set_aliyun_apt_config():
    os.system("cp ./apt/aliyun.list /etc/apt/sources.list")


def add_apt_https_support():
    os.system("apt install apt-transport-https -y")


def install_sudo(user):
    os.system("apt install sudo -y")
    cmd = "gpasswd -a %s sudo" % user
    os.system(cmd)


def install_rt_test_tools():
    os.system("apt install stress rt-tests -y")


def install_audio_manager():
    os.system("apt install pulseaudio -y")


def install_bt_client():
    os.system("apt install qbittorrent -y")


def install_proxychains(user):
    os.system("apt install proxychains4 -y")
    proc.run_as_user(
        user,
        "echo \"alias proxy='proxychains -f ~/dev/dev_init/debian/proxychains/proxychains4.conf'\" >> ~/.profile",
    )


def install_ntfs_support():
    os.system("apt install ntfs-3g -y")


def rm_unused_menu(user):
    proc.run_as_user(user, "rm -rf ~/.local/share/applications/*.wine")


def install_arm_vm_essential():
    os.system("apt install qemu-user-static -y")


def install_clang_llvm_lldb():
    os.system("apt install valgrind clang llvm lldb -y")


def install_serial_tools():
    os.system("apt install picocom lrzsz -y")
    os.system("apt install tio -y")
    os.system("apt install gtkterm cutecom -y")


def install_embedded_tools():
    # 编译 openocd 需要的库
    os.system("apt install autoconf libtool pkg-config libusb-1.0-0-dev -y")
    os.system("apt install libftdi-dev libhidapi-dev libgpiod-dev -y")

    os.system("apt install u-boot-tools qemu-system-arm -y")
    os.system("apt install i2c-tools spi-tools can-utils -y")
    os.system("apt install gdb gdbserver gdb-multiarch -y")
    os.system(
        "apt install gcc-arm-linux-gnueabi gcc-arm-none-eabi gcc-arm-linux-gnueabihf -y"
    )
    os.system("apt install mtd-utils squashfs-tools -y")


def install_wireshark(user):
    os.system("apt install wireshark -y")
    cmd = "usermod -a -G wireshark %s" % user
    os.system(cmd)


def install_qt_designer():
    os.system("apt install qttools5-dev-tools -y")
    os.system(
        "cp /usr/lib/x86_64-linux-gnu/qtchooser/qt5.conf /usr/lib/x86_64-linux-gnu/qtchooser/default.conf"
    )


def install_aptitude():
    os.system("sudo apt-get install aptitude -y")


def install_apt_file():
    os.system("sudo apt-get install apt-file -y")


def install_ios_tools():
    os.system("apt install libimobiledevice-utils ideviceinstaller ifuse -y")


def install_power_management_tool():
    os.system("apt install tlp -y")
    os.system("python ./enable_hibernate/config.py")


def install_fonts():
    os.system("apt install fonts-droid-fallback -y")


def install_theme():
    os.system("apt install faenza-icon-theme -y")


def set_peripheral_permission():
    os.system("cp ./peripheral_permission/* /etc/udev/rules.d/")
    os.system("./peripheral_permission/reload_rules.sh")


def install_chinese():
    os.system(
        "apt install xfonts-intl-chinese fonts-wqy-microhei fonts-wqy-zenhei xfonts-wqy -y"
    )
    os.system("apt install fcitx fcitx-sunpinyin fcitx-module-cloudpinyin -y")
    os.system("dpkg-reconfigure locales")


def set_shang_hai_timezone():
    os.system("timedatectl set-timezone Asia/Shanghai")


def install_image_viewer():
    os.system("apt install eom mirage -y")


def install_touch_board_driver():
    os.system("apt install xserver-xorg-input-synaptics -y")


def install_wifi_driver():
    os.system("apt install firmware-iwlwifi -y")


def make_xfce_ftp_support():
    os.system("apt install gvfs-backends -y")


def install_gdebi():
    os.system("apt install gdebi -y")


def install_toys():
    os.system("apt install cmatrix cowsay -y")


def install_useful_tools():
    os.system(
        "apt install setserial genisoimage global tree ranger silversearcher-ag git wget curl aria2 axel -y"
    )
    os.system(
        "apt install rdesktop galculator xfce4-screenshooter screenfetch gufw htop psensor -y"
    )


def install_media_tools():
    os.system("apt install ffmpeg v4l-utils -y")


def install_remote_gui_client():
    os.system("apt install remmina -y")


def install_net_tools():
    os.system("apt install uml-utilities bridge-utils net-tools tcptraceroute nmap -y")


def install_gz_to_deb():
    os.system("apt install java-package -y")


def install_file_search_tool():
    os.system("apt install catfish -y")


def install_clipboard_tool():
    os.system("apt install xfce4-clipman xfce4-clipman-plugin -y")


def install_notes_tool():
    os.system("apt install gnote -y")


def install_gantt_chart_tool():
    os.system("apt install planner -y")


def install_pdf_reader():
    os.system("apt install qpdfview qpdfview-translations -y")


def install_flow_chart_tool():
    os.system("apt install dia -y")


def install_disk_partition_tool():
    os.system("apt install gparted -y")


def install_media_player():
    os.system("apt install vlc smplayer -y")


def install_zip_tool(user):
    os.system("apt install engrampa p7zip-full zip unzip unar rar unrar -y")

    proc.run_as_user(user, "rm -rf ~/.local/share/recently-used.xbel")
    proc.run_as_user(user, "mkdir -p ~/.local/share/recently-used.xbel/")


def install_video_recorder():
    os.system("apt install vokoscreen -y")


def remove_useless_applications():
    os.system("apt purge xarchiver libreoffice* xfburn evince sane* mousepad -y")
    os.system("apt autoremove -y")
    os.system("apt install xfce4-taskmanager -y")


def add_amazing_fonts():
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
    os.system(
        "curl -fsSL https://mirrors.ustc.edu.cn/docker-ce/linux/debian/gpg | apt-key add -"
    )
    os.system(
        'add-apt-repository "deb [arch=amd64] https://mirrors.ustc.edu.cn/docker-ce/linux/debian $(lsb_release -cs) stable"'
    )
    os.system("apt update; apt install docker-ce -y")
    cmd = "usermod -a -G docker %s" % user
    os.system(cmd)
    os.system("cp -rf ./docker/daemon.json /etc/docker/daemon.json")


def install_k8s():
    os.system(
        "curl https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | apt-key add - "
    )
    os.system(
        "echo deb https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main > /etc/apt/sources.list.d/kubernetes.list"
    )
    os.system("apt update; apt install kubelet kubeadm kubectl -y")
    # 永久关闭swap
    os.system("sed -i '/ swap / s/^/#/' /etc/fstab")
    # k8s的包管理工具
    # os.system("curl -sSL https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | bash")


def install_themes(user):
    proc.run_as_user(user, "mkdir -p ~/.themes")
    proc.run_as_user(user, "cp -rf ./themes/* ~/.themes")


def init_profile(user):
    proc.run_as_user(user, "rm -rf ~/.profile")
    proc.run_as_user(user, "touch ~/.profile")


def set_open_extra_menu_alias_to_profile(user):
    proc.run_as_user(
        user,
        "echo \"alias open_extra_menu='thunar ~/.local/share/applications'\" > ~/.profile",
    )


def install_tmux(user):
    os.system("apt install tmux -y")
    proc.run_as_user(user, "cp ./tmux/tmux.conf ~/.tmux.conf")


def do_zprezto_config(user):
    os.system("apt install zsh -y")
    os.system("apt install terminator -y")

    proc.run_as_user(user, "echo 下面输入普通用户的密码")
    proc.run_as_user(user, "chsh -s $(which zsh)")
    proc.run_as_user(user, "sh ./zprezto/config.sh")


def do_install_xfce_terminal_themes(user):
    proc.run_as_user(user, "sh ./terminal_theme/install.sh")


def do_vim_config(user):
    os.system("apt install vim -y")
    proc.run_as_user(user, "sh ./vim/install.sh")


def fix_translation_bug():
    os.system("./bug_fix/i18n_fix.sh")


def fix_light_locker_bug():
    os.system("rm -rf /usr/bin/light-locker")


if __name__ == "__main__":

    add_usr_sbin_to_path_env()

    if False == proc.is_root():
        print("This program must be run as root. Aborting.")
        exit(-1)

    login_user = os.getlogin()
    set_xterm_config(login_user)

    set_aliyun_apt_config()
    do_apt_update()

    init_profile(login_user)
    add_apt_https_support()
    install_aptitude()
    install_apt_file()
    install_sudo(login_user)

    # 需要确认的放前面，减少用户等待的时间
    install_chinese()
    install_wireshark(login_user)

    install_gdebi()
    install_net_tools()
    install_useful_tools()
    install_media_tools()
    install_ios_tools()
    install_gz_to_deb()
    install_theme()
    install_fonts()
    set_shang_hai_timezone()
    install_power_management_tool()
    install_remote_gui_client()
    install_audio_manager()
    install_clang_llvm_lldb()
    install_embedded_tools()
    install_arm_vm_essential()
    install_serial_tools()
    set_peripheral_permission()
    install_toys()
    install_bt_client()
    install_image_viewer()
    install_wifi_driver()
    install_touch_board_driver()
    install_video_recorder()
    install_flow_chart_tool()
    install_disk_partition_tool()
    install_zip_tool(login_user)
    install_file_search_tool()
    install_media_player()
    install_clipboard_tool()
    install_notes_tool()
    install_pdf_reader()
    install_gantt_chart_tool()
    install_ntfs_support()
    install_qt_designer()
    install_tmux(login_user)
    add_amazing_fonts()
    make_xfce_ftp_support()

    remove_useless_applications()
    set_open_extra_menu_alias_to_profile(login_user)
    rm_unused_menu(login_user)
    install_themes(login_user)
    do_install_xfce_terminal_themes(login_user)
    install_proxychains(login_user)
    install_rt_test_tools()

    # 这个必须在zprezto之前配置
    do_vim_config(login_user)

    install_erlang(login_user)
    install_docker(login_user)

    install_k8s()

    fix_translation_bug()
    fix_light_locker_bug()

    # 太卡了，放最后
    do_zprezto_config(login_user)
