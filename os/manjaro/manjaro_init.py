#!/usr/bin/env python
# -*- coding: UTF-8 -*-


import os
import sys


pwd = os.path.dirname(os.path.abspath(__file__))
module_path = "%s/../../" % pwd
sys.path.append(module_path)
from py_mods import proc
from py_mods import file


def disable_root_history():
    os.system("echo 'yes | pacman --noconfirm -Syyu; yes | pacman --noconfirm -Scc' > ~/.bash_history")
    os.system("chattr +i ~/.bash_history")
    os.system("bash -cl 'history -c'")


def do_set_mirror_config(user):
    user_home_path = os.path.expanduser("~" + user)
    profile = user_home_path + "/" + ".profile"
    file.set_to_file(profile, 'alias pacman-mirror-select="sudo pacman-mirrors -i --geoip -m rank"', need_new_blank_line=True)


def do_upgrade():
    os.system("pacman-mirrors --geoip")
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


def set_proxy_alias_to_profile(user):
    user_home_path = os.path.expanduser("~" + user)
    profile = user_home_path + "/" + ".profile"
    file.set_to_file(profile, 'alias pon="export http_proxy=socks5://127.0.0.1:1080 https_proxy=socks5://127.0.0.1:1080"')
    file.set_to_file(profile, 'alias poff="unset http_proxy https_proxy"')


def set_peripheral_permission():
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "cp -rf %s/peripheral_permission/* /etc/udev/rules.d/" % (current_dir)
    os.system(cmd)
    cmd = "sh %s/peripheral_permission/reload_rules.sh" % (current_dir)
    os.system(cmd)


def make_colorful():
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "cp -rf %s/profile.d/* /etc/profile.d/" % (current_dir)
    os.system(cmd)
    cmd = "sed -i 's/#Color/Color/g' /etc/pacman.conf"
    os.system(cmd)


def install_api_viewer():
    os.system("yes | pacman --noconfirm -S zeal")


def install_key_tool():
    os.system("yes | pacman --noconfirm -S seahorse")


def disable_file_history(user):
    proc.run_as_user(user, "rm -rf ~/.local/share/recently-used.xbel")
    proc.run_as_user(user, "mkdir -p ~/.local/share/recently-used.xbel/")


def install_android_tools():
    os.system("yes | pacman --noconfirm -S scrcpy")


def install_toys():
    os.system("yes | pacman --noconfirm -S cmatrix cowsay")


def install_net_capture_tools(user):
    user_home_path = os.path.expanduser("~" + user)
    profile = user_home_path + "/" + ".profile"
    file.set_to_file(profile, "export SSLKEYLOGFILE=/tmp/sslkey.log", need_new_blank_line=True)
    os.system("yes | pacman --noconfirm -S wireshark-qt")
    cmd = "usermod -a -G wireshark %s" % user
    os.system(cmd)


def install_virt_manager(user):
    os.system("yes | pacman --noconfirm -S virt-manager qemu-full dnsmasq")
    os.system("yes | pacman --noconfirm -S qemu-guest-agent")
    # 虚拟机装，剪贴板共享程序
    os.system("yes | pacman --noconfirm -S spice-vdagent")
    os.system("systemctl enable libvirtd")
    os.system("systemctl start libvirtd")
    cmd = "usermod -a -G libvirt %s" % user
    os.system(cmd)


def install_qt5ct():
    os.system("yes | pacman --noconfirm -S qt5ct")


def install_docker(user):
    os.system("yes | pacman --noconfirm -S docker")
    cmd = "usermod -a -G docker %s" % user
    os.system(cmd)

    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "mkdir -p /etc/docker/; cp -rf %s/docker/daemon.json /etc/docker/daemon.json" % (current_dir)
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


def install_disk_tools():
    os.system("yes | pacman --noconfirm -S gparted ventoy")


def install_essential_fonts():
    os.system("yes | pacman --noconfirm -S wqy-bitmapfont wqy-microhei wqy-microhei-lite wqy-zenhei")
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "cp -rf %s/fonts/* /usr/share/fonts/" % (current_dir)
    os.system(cmd)
    os.system("fc-cache -fv")


def install_sync_tool():
    os.system("yes | pacman --noconfirm -S grsync rsync")


def install_serial_tools():
    os.system("yes | pacman --noconfirm -S picocom lrzsz")


def install_chinese_input(user):
    os.system("yes | pacman --noconfirm -S manjaro-asian-input-support-fcitx5 fcitx5-chinese-addons")
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "mkdir -p ~/.config/fcitx5/"
    proc.run_as_user(user, cmd)
    cmd = "cp -rf %s/fcitx/config/* ~/.config/fcitx5/" % (current_dir)
    proc.run_as_user(user, cmd)
    cmd = "mkdir -p ~/.local/share/fcitx5/themes/"
    proc.run_as_user(user, cmd)
    cmd = "cp -rf %s/fcitx/themes/* ~/.local/share/fcitx5/themes/" % (current_dir)
    proc.run_as_user(user, cmd)


def englishization_user_dir_name(user):
    proc.run_as_user(user, "mv ~/桌面 ~/Desktop")
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "cp -rf %s/englih_user_dir/user-dirs.dirs ~/.config/" % (current_dir)
    proc.run_as_user(user, cmd)
    proc.run_as_user(user, "mkdir -p ~/.templates")


def do_zsh_config(user):
    os.system("yes | pacman --noconfirm -S zsh")
    cmd = "chsh -s $(which zsh) %s" % user
    os.system(cmd)
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "sh %s/zsh/config.sh" % (current_dir)
    proc.run_as_user(user, cmd)
    os.system("rm -rf /etc/zsh/zprofile; touch /etc/zsh/zshenv")
    file.set_to_file("/etc/zsh/zshenv", 'emulate sh -c "source /etc/profile"')


def install_asdf(user):
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "python %s/../../development/asdf/asdf_init.py" % (current_dir)
    proc.run_as_user(user, cmd)


def install_erlang(user):
    os.system("yes | pacman --noconfirm -S erlang")
    user_home_path = os.path.expanduser("~" + user)
    profile = user_home_path + "/" + ".profile"
    file.set_to_file(profile, 'export ERL_AFLAGS="-kernel shell_history enabled"')


def install_elixir(user):
    os.system("yes | pacman --noconfirm -S elixir")
    os.system("yes | pacman --noconfirm -S inotify-tools")
    user_home_path = os.path.expanduser("~" + user)
    profile = user_home_path + "/" + ".profile"
    file.set_to_file(profile, 'export HEX_UNSAFE_HTTPS=1')
    file.set_to_file(profile, 'export HEX_MIRROR="https://hexpm.upyun.com"')


def install_terminator(user):
    os.system("yes | pacman --noconfirm -S terminator")
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "mkdir -p ~/.config/terminator/"
    proc.run_as_user(user, cmd)
    cmd = "cp -rf %s/../../development/terminator/config ~/.config/terminator/" % (current_dir)
    proc.run_as_user(user, cmd)


def install_build_essential():
    os.system("yes | pacman --noconfirm -S base-devel")


def install_pg_essential():
    os.system("yes | pacman --noconfirm -S postgresql-libs")


def install_image_viewer():
    os.system("yes | pacman --noconfirm -S phonon-qt5-gstreamer gwenview")


def install_useful_tools():
    tool_list = [
        "virt-what",
        "progress",
        "screen",
        "strace",
        "upx",
        "duf",
        "autossh",
        "xorg-xinput",
        "file-roller",
        "light-locker",
        "p7zip",
        "socat",
        "expect",
        "cdrtools",
        "axel",
        "aria2",
        "curl",
        "wget",
        "ranger",
        "tree",
        "neofetch",
        "screenfetch",
        "the_silver_searcher",
    ]
    for tool in tool_list:
        cmd = "yes | pacman --noconfirm -S %s" % tool
        os.system(cmd)


def install_wezterm(user):
    os.system("yes | pacman --noconfirm -S wezterm")
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "sh %s/../../development/wezterm/install.sh" % (current_dir)
    proc.run_as_user(user, cmd)


def install_zellij():
    os.system("yes | pacman --noconfirm -S zellij")


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
        "avahi-discover.desktop",
        "kcm_fcitx5.desktop",
        "kcm_kaccounts.desktop",
        "kcm_trash.desktop"
    ]
    for link in links:
        cmd = "rm -rf /usr/share/applications/%s" % link
        os.system(cmd)


def remove_useless_applications():
    app_list = [
        "engrampa",
        "mousepad",
        "stoken",
        "kvantum",
        "manjaro-hello",
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
        cmd = "yes | pacman --noconfirm -Rcns  %s" % app
        os.system(cmd)


def install_ansible_essential():
    os.system("yes | pacman --noconfirm -S sshpass")


def install_ssh_server():
    os.system("yes | pacman --noconfirm -S openssh")
    os.system("systemctl enable sshd")


def install_media_player():
    os.system("yes | pacman --noconfirm -S vlc smplayer audacious")


def install_screen_recorder():
    os.system("yes | pacman --noconfirm -S vokoscreen")


def install_color_picker():
    os.system("yes | pacman --noconfirm -S kcolorchooser")


def install_proxychains(user):
    os.system("yes | pacman --noconfirm -S proxychains-ng")
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "cp -rf %s/../../development/proxychains/proxychains.conf /etc/" % (current_dir)
    os.system(cmd)
    user_home_path = os.path.expanduser("~" + user)
    profile = user_home_path + "/" + ".profile"
    file.set_to_file(profile, 'alias proxy="proxychains"')


def do_vim_config(user):
    os.system("yes | pacman --noconfirm -S xfce4-terminal ripgrep xclip neovim")
    os.system("rm -rf /usr/share/applications/vim.desktop")
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "sh %s/../../development/editor/nvim/install.sh" % (current_dir)
    proc.run_as_user(user, cmd)


def do_emacs_config(user):
    os.system("yes | pacman --noconfirm -S emacs")
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "sh %s/../../development/editor/emacs/install.sh" % (current_dir)
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


def set_ntp_time():
    os.system("timedatectl set-ntp true")
    os.system("timedatectl set-timezone Asia/Shanghai")


def install_musl():
    os.system("yes | pacman --noconfirm -S musl")


def install_remote_desktop():
    os.system("yes | pacman --noconfirm -S rdesktop")


def install_ios_essential():
    os.system("yes | pacman --noconfirm -S libimobiledevice")


def install_net_tools():
    os.system("yes | pacman --noconfirm -S sshfs traceroute bridge-utils netctl net-tools dnsutils gnu-netcat nmap")


def install_embedded_tools():
    os.system("yes | pacman --noconfirm -S uboot-tools qemu-system-arm")
    os.system("yes | pacman --noconfirm -S i2c-tools")
    os.system("yes | pacman --noconfirm -S gdb lldb openocd")
    os.system("yes | pacman --noconfirm -S arm-none-eabi-gcc arm-none-eabi-newlib")
    os.system("yes | pacman --noconfirm -S mtd-utils squashfs-tools")


def install_zig_dev():
    os.system("yes | pacman --noconfirm -S zig zls")


if __name__ == "__main__":
    if False == proc.is_root():
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
    set_proxy_alias_to_profile(login_user)
    disable_file_history(login_user)
    set_ntp_time()
    do_set_mirror_config(login_user)

    do_upgrade()

    remove_useless_applications()

    disable_pc_beep()
    englishization_user_dir_name(login_user)
    install_build_essential()
    make_git_default_config(login_user)
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
    install_wezterm(login_user)
    install_zellij()
    install_ansible_essential()
    install_media_player()
    install_screen_recorder()
    install_printer_essential()
    install_qt5ct()
    install_zig_dev()
    install_musl()
    install_erlang(login_user)
    install_elixir(login_user)
    install_net_capture_tools(login_user)
    install_virt_manager(login_user)
    install_proxychains(login_user)
    install_docker(login_user)
    install_useful_tools()
    install_image_viewer()
    install_terminator(login_user)
    do_vim_config(login_user)
    do_emacs_config(login_user)
    install_chinese_input(login_user)
    set_peripheral_permission()

    install_serial_tools()
    install_android_tools()

    install_net_tools()
    install_remote_desktop()
    install_embedded_tools()
    install_ios_essential()

    remove_useless_files()
    install_asdf(login_user)

    # 太卡了，放最后
    do_zsh_config(login_user)
    fix_translation_bug(login_user)
