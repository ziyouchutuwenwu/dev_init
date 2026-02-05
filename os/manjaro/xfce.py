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
        "echo 'yes | pacman --noconfirm -Syyu; yes | pacman --noconfirm -Scc' > ~/.bash_history"
    )
    os.system("chattr +i ~/.bash_history")
    os.system("bash -cl 'history -c'")


def set_mirror():
    os.system("pacman-mirrors --timezone -m rank")


def update_keyring():
    os.system("yes | pacman --noconfirm -S archlinux-keyring manjaro-keyring")
    os.system("yes | pacman-key --populate")
    os.system("yes | pacman --noconfirm -S ca-certificates")


def do_upgrade():
    os.system("yes | pacman --noconfirm -Syyu")


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


def init_profile(user):
    proc.run_as_user(user, "rm -rf ~/.profile")
    proc.run_as_user(user, "touch ~/.profile")
    os.system("rm -rf ~/.profile")
    os.system("touch ~/.profile")


def set_dev_rules():
    cmd = "mkdir -p /etc/udev/rules.d"
    os.system(cmd)
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "cp -rf %s/dev_rules/*.rules /etc/udev/rules.d/" % (current_dir)
    os.system(cmd)
    cmd = "udevadm control --reload-rules; udevadm trigger"
    os.system(cmd)


def make_colorful():
    cmd = "sed -i 's/#Color/Color/g' /etc/pacman.conf"
    os.system(cmd)


def install_api_viewer():
    os.system("yes | pacman --noconfirm -S zeal")


def install_key_tool():
    os.system("yes | pacman --noconfirm -S seahorse")


def set_global_profiles():
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "cp -rf %s/profile/*.sh /etc/profile.d/" % (current_dir)
    os.system(cmd)
    cmd = "mkdir -p /usr/local/etc/profile.d"
    os.system(cmd)
    cmd = "cp -rf %s/profile/profile.d/* /usr/local/etc/profile.d/" % (current_dir)
    os.system(cmd)


def disable_file_history(user):
    proc.run_as_user(user, "rm -rf ~/.local/share/recently-used.xbel")
    proc.run_as_user(user, "mkdir -p ~/.local/share/recently-used.xbel/")


def install_android_tools():
    os.system("yes | pacman --noconfirm -S scrcpy")


def install_toys():
    os.system("yes | pacman --noconfirm -S cmatrix cowsay")


def install_sniffer(user):
    os.system("yes | pacman --noconfirm -S wireshark-qt")
    cmd = "usermod -a -G wireshark %s" % user
    os.system(cmd)
    os.system("yes | pacman --noconfirm -S tcpdump")


def install_vm_essential():
    # 虚拟机装，剪贴板共享程序
    os.system("yes | pacman --noconfirm -S spice-vdagent")


def install_virt_manager(user):
    os.system("yes | pacman --noconfirm -S virt-manager qemu-full dnsmasq")
    os.system("yes | pacman --noconfirm -S qemu-guest-agent")
    groups = [
        "libvirt",
        "libvirt-qemu",
        "kvm",
    ]
    for group in groups:
        cmd = "usermod -aG %s %s" % (group, user)
        os.system(cmd)
    os.system("systemctl enable libvirtd")
    os.system("systemctl start libvirtd")


def install_qt5ct():
    os.system("yes | pacman --noconfirm -S qt5ct")


def install_docker(user):
    os.system("yes | pacman --noconfirm -S docker")
    cmd = "usermod -a -G docker %s" % user
    os.system(cmd)
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "mkdir -p /etc/docker/; cp -rf %s/docker/daemon.json /etc/docker/" % (
        current_dir
    )
    os.system(cmd)
    os.system("systemctl enable docker.service")


def disable_pc_beep():
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "cp -rf %s/mod_blacklist/blacklist.conf /etc/modprobe.d/" % (current_dir)
    os.system(cmd)


def install_nvidia_drivers():
    os.system("mhwd -r pci video-linux")
    os.system("mhwd -r pci video-nvidia")
    os.system("mhwd -r pci video-hybrid-intel-nvidia-prime")
    os.system("yes | pacman --noconfirm -S mesa-utils nvidia-prime")


def install_python_tools():
    os.system("yes | pacman --noconfirm -S uv")


def install_disk_tools():
    os.system("yes | pacman --noconfirm -S gparted ventoy")


def install_essential_fonts():
    os.system(
        "yes | pacman --noconfirm -S wqy-bitmapfont wqy-microhei wqy-microhei-lite wqy-zenhei"
    )
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "cp -rf %s/fonts/* /usr/share/fonts/" % (current_dir)
    os.system(cmd)
    os.system("fc-cache -fv")


def install_sync_tool():
    os.system("yes | pacman --noconfirm -S grsync rsync")


def install_serial_tools(user):
    os.system("yes | pacman --noconfirm -S picocom lrzsz")
    cmd = "usermod -a -G uucp %s" % user
    os.system(cmd)


def install_chinese_input(user):
    os.system(
        "yes | pacman --noconfirm -S manjaro-asian-input-support-fcitx5 fcitx5-chinese-addons"
    )
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "mkdir -p ~/.config/fcitx5/"
    proc.run_as_user(user, cmd)
    cmd = "cp -rf %s/fcitx/config/* ~/.config/fcitx5/" % (current_dir)
    proc.run_as_user(user, cmd)
    cmd = "mkdir -p ~/.local/share/fcitx5/themes/"
    proc.run_as_user(user, cmd)
    cmd = "cp -rf %s/fcitx/themes/* ~/.local/share/fcitx5/themes/" % (current_dir)
    proc.run_as_user(user, cmd)


def make_user_dir_en(user):
    proc.run_as_user(user, "mkdir -p ~/desktop")
    proc.run_as_user(user, "mkdir -p ~/.config")
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "cp -rf %s/englih_user_dir/user-dirs.dirs ~/.config/" % (current_dir)
    proc.run_as_user(user, cmd)
    proc.run_as_user(user, "mkdir -p ~/.templates")


def do_zsh_config(user):
    os.system("yes | pacman --noconfirm -S zsh")
    os.system("usermod -s $(which zsh) root")
    cmd = "usermod -s $(which zsh) %s" % (user)
    os.system(cmd)
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "sh %s/zsh/global/config.sh" % (current_dir)
    os.system(cmd)
    cmd = "sh %s/zsh/root/config.sh" % (current_dir)
    os.system(cmd)
    cmd = "sh %s/zsh/user/config.sh" % (current_dir)
    proc.run_as_user(user, cmd)


def install_beam():
    os.system("yes | pacman --noconfirm -S jre-openjdk erlang rebar3")
    os.system("yes | pacman --noconfirm -S elixir")
    os.system("yes | pacman --noconfirm -S inotify-tools")


def install_terminator(user):
    os.system("yes | pacman --noconfirm -S terminator")
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "sh %s/../../development/terminal/terminator/install.sh" % (current_dir)
    proc.run_as_user(user, cmd)


def install_tmux():
    os.system("yes | pacman --noconfirm -S tmux")
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "cp -rf %s/../../development/terminal/tmux/config/* /etc/" % (current_dir)
    os.system(cmd)


def install_build_essential():
    os.system("yes | pacman --noconfirm -S base-devel")


def install_pg_essential():
    os.system("yes | pacman --noconfirm -S postgresql-libs")


def install_zip_essential():
    os.system("yes | pacman --noconfirm -S p7zip zip unzip")


def install_search_tools():
    os.system("yes | pacman --noconfirm -S fd ripgrep")


def install_encoding_tools():
    os.system("yes | pacman --noconfirm -S enca")


def install_useful_tools():
    tool_list = [
        "reptyr",
        "xclip",
        "binaryen",
        "virt-what",
        "progress",
        "screen",
        "strace",
        "upx",
        "duf",
        "autossh",
        "xorg-xinput",
        "xarchiver",
        "qalculate-gtk",
        "socat",
        "expect",
        "cdrtools",
        "axel",
        "aria2",
        "curl",
        "wget",
        "tree",
        "fastfetch",
    ]
    for tool in tool_list:
        cmd = "yes | pacman --noconfirm -S %s" % tool
        os.system(cmd)


def make_git_default_config(user):
    os.system("yes | pacman --noconfirm -S git")
    proc.run_as_user(user, "git config --global core.autocrlf false")
    proc.run_as_user(user, "git config --global core.quotepath off")


def remove_useless_files():
    os.system("rm -rf /desktopfs-pkgs.txt /rootfs-pkgs.txt")
    links = [
        "manjaro-hello.desktop",
        "manjaro-documentation.desktop",
        "hp-uiscan.desktop",
        "kcm_fcitx5.desktop",
        "kcm_kaccounts.desktop",
        "kcm_trash.desktop",
        "org.kde.kiod6.desktop",
    ]
    for link in links:
        cmd = "rm -rf /usr/share/applications/%s" % link
        os.system(cmd)


def remove_useless_applications():
    app_list = [
        "ibus",
        "galculator",
        "engrampa",
        "micro",
        "stoken",
        "kvantum",
        "timeshift",
        "manjaro-hello",
        "xfce4-terminal",
        "xfce4-clipman",
        "firefox",
        "evince",
        "xfburn",
        "pidgin",
        "gimp",
        "gcolor3",
        "viewnior",
        "thunderbird",
        "hexchat",
    ]
    for app in app_list:
        cmd = "yes | pacman --noconfirm -Rcns %s" % app
        os.system(cmd)


def remove_catfish(user):
    os.system("yes | pacman --noconfirm -Rcns catfish")
    cmd = (
        r"sed -i '/<action>/,/<\/action>/ { "
        r"/<icon>system-search<\/icon>/,/<\/action>/d "
        r"}' ~/.config/Thunar/uca.xml"
    )
    proc.run_as_user(user, cmd)


def install_ansible_essential():
    os.system("yes | pacman --noconfirm -S sshpass")


def install_ssh_server():
    os.system("yes | pacman --noconfirm -S openssh")
    os.system("sed -i 's/^#X11Forwarding no/X11Forwarding yes/' /etc/ssh/sshd_config")
    os.system(
        "sed -i 's/^#\\?GatewayPorts.*/GatewayPorts clientspecified/' /etc/ssh/sshd_config"
    )
    os.system("systemctl restart sshd; systemctl enable sshd")


def install_media_player():
    os.system("yes | pacman --noconfirm -S vlc smplayer audacious")


def install_screen_recorder():
    os.system("yes | pacman --noconfirm -S vokoscreen")


def install_color_picker():
    os.system("yes | pacman --noconfirm -S kcolorchooser")


def install_proxychains():
    os.system("yes | pacman --noconfirm -S proxychains-ng")
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = (
        "cp -rf %s/../../development/proxy/proxychains/proxychains.conf /etc/proxychains.conf"
        % (current_dir)
    )
    os.system(cmd)


def install_privoxy():
    os.system("yes | pacman --noconfirm -S privoxy")
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "cp -rf %s/../../development/proxy/privoxy/config /etc/privoxy/config" % (
        current_dir
    )
    os.system(cmd)
    os.system("systemctl daemon-reload; systemctl enable privoxy --now")


def do_vim_config(user):
    os.system("yes | pacman --noconfirm -S neovim")
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "sh %s/../../development/editor/nvim/install.sh" % (current_dir)
    proc.run_as_user(user, cmd)


def install_printer_essential():
    os.system("yes | pacman --noconfirm -S system-config-printer")
    os.system("yes | pacman --noconfirm -S cups cups-browsed")
    os.system("systemctl enable cups-browsed.service --now")
    os.system("systemctl enable cups.service --now")


def fix_translation_bug(user):
    cmd = "mkdir -p ~/.local/share/applications/"
    proc.run_as_user(user, cmd)
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "cp -rf %s/translations/* ~/.local/share/applications/" % (current_dir)
    proc.run_as_user(user, cmd)
    cmd = "update-desktop-database ~/.local/share/applications"
    proc.run_as_user(user, cmd)


def set_ntp():
    os.system("timedatectl set-ntp true")


def set_timezone():
    os.system("timedatectl set-timezone Asia/Shanghai")


def install_remote_desktop():
    os.system("yes | pacman --noconfirm -S freerdp")


def install_ios_essential():
    os.system("yes | pacman --noconfirm -S libimobiledevice")


def install_netcat():
    os.system("yes | pacman --noconfirm -S nmap")
    os.system("ln -s $(which ncat) /usr/bin/nc")


def install_net_tools():
    app_list = [
        "whois",
        "sshfs",
        "traceroute",
        "bridge-utils",
        "netctl",
        "net-tools",
        "dnsutils",
    ]
    for app in app_list:
        cmd = "yes | pacman --noconfirm -S %s" % app
        os.system(cmd)


def install_embedded_tools():
    os.system("yes | pacman --noconfirm -S gdb lldb")
    os.system("yes | pacman --noconfirm -S arm-none-eabi-gcc arm-none-eabi-newlib")
    os.system("yes | pacman --noconfirm -S uboot-tools qemu-system-arm")
    os.system("yes | pacman --noconfirm -S i2c-tools")
    os.system("yes | pacman --noconfirm -S mtd-utils squashfs-tools")


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

    disable_root_history()
    make_colorful()
    set_swapping_config()
    set_fs_watches_config()

    init_profile(login_user)
    disable_file_history(login_user)
    set_ntp()
    set_timezone()
    set_mirror()
    update_keyring()
    do_upgrade()

    remove_useless_applications()
    remove_catfish(login_user)

    disable_pc_beep()
    make_user_dir_en(login_user)
    install_build_essential()
    make_git_default_config(login_user)
    install_zip_essential()
    install_python_tools()
    install_toys()
    install_nvidia_drivers()
    install_color_picker()
    install_pg_essential()
    install_disk_tools()
    install_api_viewer()
    install_key_tool()
    install_essential_fonts()
    install_sync_tool()
    install_ssh_server()
    install_ansible_essential()
    install_media_player()
    install_screen_recorder()
    install_printer_essential()
    install_qt5ct()
    set_global_profiles()
    install_beam()
    install_sniffer(login_user)
    install_vm_essential()
    install_virt_manager(login_user)
    install_proxychains()
    install_privoxy()
    install_docker(login_user)
    install_useful_tools()
    install_terminator(login_user)
    install_tmux()
    do_vim_config(login_user)
    install_chinese_input(login_user)

    set_dev_rules()
    install_serial_tools(login_user)
    install_android_tools()
    install_search_tools()
    install_encoding_tools()
    install_net_tools()
    install_netcat()
    install_remote_desktop()
    install_embedded_tools()
    install_ios_essential()

    remove_useless_files()

    # 太卡了，放最后
    do_zsh_config(login_user)
    fix_translation_bug(login_user)
