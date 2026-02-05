#!/usr/bin/env python
# -*- coding: UTF-8 -*-


import sys

sys.dont_write_bytecode = True

import os

pwd = os.path.dirname(os.path.abspath(__file__))
module_path = "%s/../../" % pwd
sys.path.append(module_path)
from py_mods import proc


def make_user_dir_en(user):
    proc.run_as_user(user, "mkdir -p ~/desktop")
    proc.run_as_user(user, "mkdir -p ~/.config")
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "cp -rf %s/englih_user_dir/user-dirs.dirs ~/.config/" % (current_dir)
    proc.run_as_user(user, cmd)
    proc.run_as_user(user, "mkdir -p ~/.templates")


def run_root_console_script(mirror_name):
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "python %s/console.py %s" % (current_dir, mirror_name)
    os.system(cmd)


def install_firmware():
    os.system("xbps-install -y linux-firmware")


def disable_pc_beep():
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "cp -rf %s/mod_blacklist/blacklist.conf /etc/modprobe.d/" % (current_dir)
    os.system(cmd)


def install_fcitx(user):
    # 环境变量在 /usr/local/etc/profile.d/fcitx.sh 里面
    os.system("xbps-install -y fcitx5 fcitx5-configtool fcitx5-chinese-addons")
    # gtk 相关解决了 vscode 下，会出现字母乱跳的情况
    # qt5 解决了 qpdfview 里面不能呼唤输入法的问题
    os.system("xbps-install -y fcitx5-qt5 fcitx5-gtk+2 fcitx5-gtk+3 fcitx5-gtk4")
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "mkdir -p ~/.config/fcitx5/"
    proc.run_as_user(user, cmd)
    cmd = "cp -rf %s/fcitx/config/* ~/.config/fcitx5/" % (current_dir)
    proc.run_as_user(user, cmd)
    cmd = "mkdir -p ~/.local/share/fcitx5/themes/"
    proc.run_as_user(user, cmd)
    cmd = "cp -rf %s/fcitx/themes/* ~/.local/share/fcitx5/themes/" % (current_dir)
    proc.run_as_user(user, cmd)


def install_proxychains():
    os.system("xbps-install -y proxychains-ng")
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = (
        "cp -rf %s/../../development/proxy/proxychains/proxychains.conf /etc/proxychains.conf"
        % (current_dir)
    )
    os.system(cmd)


def install_privoxy():
    os.system("xbps-install -y privoxy")
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "cp -rf %s/../../development/proxy/privoxy/config /etc/privoxy/config" % (
        current_dir
    )
    os.system(cmd)
    os.system("ln -s /etc/sv/privoxy /var/service/")


def install_browser():
    os.system("xbps-install -y chromium")


def install_beam():
    os.system("xbps-install -y erlang rebar3")
    os.system("xbps-install -y elixir")


def install_remote_desktop():
    os.system("xbps-install -y freerdp")


def install_filemon_tool():
    os.system("xbps-install -y inotify-tools watchman")


def install_pg_essential():
    os.system("xbps-install -y postgresql-libs")


def install_tools():
    tool_list = [
        "xfce4-screenshooter",
        "gparted",
        "menulibre",
    ]
    for tool in tool_list:
        cmd = "xbps-install -y %s" % tool
        os.system(cmd)


def install_login_setting():
    os.system("xbps-install -y lightdm-gtk-greeter-settings")


def install_embedded_tools():
    os.system("xbps-install -y gdb-multiarch")
    os.system("xbps-install -y qemu-user-static")
    os.system("xbps-install -y u-boot-tools")
    os.system("xbps-install -y i2c-tools can-utils")
    os.system("xbps-install -y mtd-utils squashfs-tools")


def install_serial_tools(user):
    os.system("xbps-install -y picocom lrzsz")
    os.system("xbps-install -y tio")
    cmd = "usermod -a -G dialout %s" % user
    os.system(cmd)


def install_terminator(user):
    os.system("xbps-install -y terminator")
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "sh %s/../../development/terminal/terminator/install.sh" % (current_dir)
    proc.run_as_user(user, cmd)


def install_pdf_reader():
    os.system("xbps-install -y qpdfview")


def disable_file_history(user):
    proc.run_as_user(user, "rm -rf ~/.local/share/recently-used.xbel")
    proc.run_as_user(user, "mkdir -p ~/.local/share/recently-used.xbel/")


def install_themes(user):
    os.system("xbps-install -y faenza-icon-theme")
    proc.run_as_user(user, "mkdir -p ~/.themes")
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "cp -rf %s/themes/* ~/.themes" % (current_dir)
    proc.run_as_user(user, cmd)


def do_vim_config(user):
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "sh %s/../../development/editor/nvim/install.sh" % (current_dir)
    proc.run_as_user(user, cmd)


def do_zsh_config(user):
    cmd = "usermod -s /usr/bin/zsh %s" % (user)
    os.system(cmd)
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "sh %s/zsh/user/config.sh" % (current_dir)
    proc.run_as_user(user, cmd)


def install_media_player():
    os.system("xbps-install -y ffmpeg vlc smplayer mplayer audacious")


def install_unzipper():
    os.system("xbps-install -y xarchiver thunar-archive-plugin")


def install_vm_essential():
    # 虚拟机装，剪贴板共享程序
    os.system("xbps-install -y spice-vdagent")
    os.system("ln -s /etc/sv/spice-vdagentd /var/service/")


def install_virt_manager(user):
    os.system("xbps-install -y virt-manager qemu")
    os.system("ln -s /etc/sv/libvirtd /var/service/")
    os.system("ln -s /etc/sv/virtlogd /var/service/")
    os.system("sv start libvirtd")
    groups = [
        "libvirt",
        "kvm",
    ]
    for group in groups:
        cmd = "usermod -aG %s %s" % (group, user)
        os.system(cmd)


def install_sniffer(user):
    os.system("xbps-install -y wireshark-qt")
    cmd = "usermod -a -G wireshark %s" % user
    os.system(cmd)
    os.system("xbps-install -y tcpdump")


def install_qtct():
    os.system("xbps-install -y qt5ct")


def install_image_viewer():
    os.system("xbps-install -y gpicview")


def fix_translation_bug(user):
    cmd = "mkdir -p ~/.local/share/applications/"
    proc.run_as_user(user, cmd)
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "cp -rf %s/translations/* ~/.local/share/applications/" % (current_dir)
    proc.run_as_user(user, cmd)
    cmd = "update-desktop-database ~/.local/share/applications"
    proc.run_as_user(user, cmd)


def set_brightness():
    os.system("xbps-install -y brightnessctl")
    os.system("mkdir -p /etc/sv/brightness")
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "cp -rf %s/brightness/* /etc/sv/brightness/" % (current_dir)
    os.system(cmd)
    os.system("chmod a+x /etc/sv/brightness/run")
    os.system("ln -s /etc/sv/brightness /var/service/")


def do_clean():
    os.system("xbps-remove -Ooy")


if __name__ == "__main__":
    if not proc.is_root():
        print("This program must be run as root. Aborting.")
        exit(-1)

    script_name = str(sys.argv[0])
    login_user = os.getlogin()
    if len(sys.argv) < 2:
        print("用法: %s tuna" % script_name)
        exit(-1)

    mirror_name = str(sys.argv[1])

    run_root_console_script(mirror_name)
    disable_pc_beep()
    make_user_dir_en(login_user)
    install_firmware()
    install_themes(login_user)
    install_browser()
    install_fcitx(login_user)
    install_beam()
    install_terminator(login_user)
    install_proxychains()
    install_privoxy()
    install_serial_tools()
    install_embedded_tools()
    install_sniffer(login_user)
    install_qtct()
    install_remote_desktop()
    install_media_player()
    install_pg_essential()
    disable_file_history(login_user)
    install_pdf_reader()
    install_unzipper()
    install_login_setting()
    install_image_viewer()
    install_vm_essential()
    install_virt_manager(login_user)
    install_tools()
    install_filemon_tool()
    do_vim_config(login_user)
    do_zsh_config(login_user)
    fix_translation_bug(login_user)
    set_brightness()
    do_clean()
