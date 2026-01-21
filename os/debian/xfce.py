#!/usr/bin/env python
# -*- coding: UTF-8 -*-


import sys

sys.dont_write_bytecode = True

import os

pwd = os.path.dirname(os.path.abspath(__file__))
module_path = "%s/../../" % pwd
sys.path.append(module_path)
from py_mods import proc


# 不同的脚本都需要定义，否则会出现错误
def add_usr_sbin_to_path_env():
    os.environ["PATH"] += ":/usr/sbin/"


def enable_sleep():
    # 自定义的配置文件内禁用了 sleep
    cmd = "rm -rf /etc/systemd/sleep.conf.d"
    os.system(cmd)


def install_beam():
    os.system("apt install -y erlang rebar3")
    os.system("apt install -y elixir")
    os.system("apt purge -y erlang-jinterface")


def install_sudo(user):
    os.system("apt install -y sudo")
    cmd = "gpasswd -a %s sudo" % user
    os.system(cmd)


def install_rt_test_tools():
    os.system("apt install -y stress rt-tests")


def install_embedded_tools():
    os.system("apt install -y openocd")
    os.system("apt install -y gdbserver gdb-multiarch")
    os.system(
        "apt install -y gcc-arm-linux-gnueabi gcc-arm-none-eabi gcc-arm-linux-gnueabihf"
    )
    os.system("apt install -y qemu-user-static")
    os.system("apt install -y u-boot-tools")
    os.system("apt install -y i2c-tools spi-tools can-utils")
    os.system("apt install -y mtd-utils squashfs-tools")


def install_clang_llvm_lldb():
    os.system("apt install -y valgrind clang llvm lldb")


def install_audio_manager():
    os.system("apt install -y pulseaudio")


def install_login_setting():
    os.system("apt install -y lightdm-gtk-greeter-settings")


def install_proxychains():
    os.system("apt install -y proxychains4")
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = (
        "cp -rf %s/../../development/proxy/proxychains/proxychains.conf /etc/proxychains4.conf"
        % (current_dir)
    )
    os.system(cmd)


def install_privoxy():
    os.system("apt install -y privoxy")
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "cp -rf %s/../../development/proxy/privoxy/config /etc/privoxy/config" % (
        current_dir
    )
    os.system(cmd)
    os.system("systemctl daemon-reload; systemctl enable privoxy")


def disable_pc_beep():
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "cp -rf %s/mod_blacklist/blacklist.conf /etc/modprobe.d/" % (current_dir)
    os.system(cmd)


def make_user_dir_en(user):
    proc.run_as_user(user, "mkdir -p ~/desktop")
    proc.run_as_user(user, "mkdir -p ~/.config")
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "cp -rf %s/englih_user_dir/user-dirs.dirs ~/.config/" % (current_dir)
    proc.run_as_user(user, cmd)
    proc.run_as_user(user, "mkdir -p ~/.templates")


def make_git_default_config(user):
    proc.run_as_user(user, "git config --global core.autocrlf false")
    proc.run_as_user(user, "git config --global core.quotepath off")


def install_color_picker():
    os.system("apt install -y kcolorchooser")


def install_api_viewer():
    os.system("apt install -y zeal")


def install_serial_tools(user):
    os.system("apt install -y picocom lrzsz")
    os.system("apt install -y tio")
    cmd = "usermod -a -G dialout %s" % user
    os.system(cmd)


def install_sniffer(user):
    os.system(
        'echo "wireshark-common wireshark-common/install-setuid boolean true" | debconf-set-selections'
    )
    os.system("apt install -y wireshark")
    cmd = "usermod -a -G wireshark %s" % user
    os.system(cmd)
    os.system("apt install -y tcpdump")


def install_vm_essential():
    # 虚拟机装，剪贴板共享程序
    os.system("apt install -y spice-vdagent")


def install_virt_manager(user):
    os.system("apt install -y virt-manager")
    install_list = [
        "qemu-system",
        "qemu-system-arm",
        "qemu-system-mips",
        "qemu-system-misc",
        "qemu-system-ppc",
    ]
    for item in install_list:
        cmd = "apt install -y %s" % item
        os.system(cmd)
    # 物理机装，剪贴板共享程序
    os.system("apt install -y qemu-guest-agent")
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


def install_qt_setting_tool():
    os.system("apt install -y qt5ct")


def install_pg_essential():
    os.system("apt install -y libpq-dev")


def install_ios_tools():
    os.system("apt install -y libimobiledevice-utils ideviceinstaller ifuse")


def install_power_management_tool():
    os.system("apt install -y tlp")


def set_dev_rules():
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "cp -rf %s/dev_rules/* /etc/udev/rules.d/" % (current_dir)
    os.system(cmd)
    cmd = "sh %s/dev_rules/reload_rules.sh" % (current_dir)
    os.system(cmd)


def install_chinese_fonts():
    os.system(
        "apt install -y xfonts-intl-chinese fonts-wqy-microhei fonts-wqy-zenhei xfonts-wqy"
    )


def install_fcitx(user):
    os.system("apt install -y fcitx5 fcitx5-chinese-addons")
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "mkdir -p ~/.config/fcitx5/"
    proc.run_as_user(user, cmd)
    cmd = "cp -rf %s/fcitx/config/* ~/.config/fcitx5/" % (current_dir)
    proc.run_as_user(user, cmd)
    cmd = "mkdir -p ~/.local/share/fcitx5/themes/"
    proc.run_as_user(user, cmd)
    cmd = "cp -rf %s/fcitx/themes/* ~/.local/share/fcitx5/themes/" % (current_dir)
    proc.run_as_user(user, cmd)


def install_image_viewer():
    os.system("apt install -y gpicview")


def install_touch_board_driver():
    os.system("apt install -y xserver-xorg-input-synaptics")


def make_xfce_ftp_support():
    os.system("apt install -y gvfs-backends")


def install_remote_gui_client():
    os.system("apt install -y rdesktop")


def install_notes_tool():
    os.system("apt install -y gnote")


def install_pdf_reader():
    os.system("apt install -y qpdfview")


def install_disk_partition_tool():
    os.system("apt install -y gparted")


def install_media_player():
    os.system("apt install -y ffmpeg vlc smplayer audacious")


def install_unzipper():
    os.system("apt install -y xarchiver")


def disable_file_history(user):
    proc.run_as_user(user, "rm -rf ~/.local/share/recently-used.xbel")
    proc.run_as_user(user, "mkdir -p ~/.local/share/recently-used.xbel/")


def install_video_recorder():
    os.system("apt install -y vokoscreen")


def do_clean_after_install():
    app_list = [
        "libproxy-tools",
        # virt-manager 会自动装这个
        "netcat-openbsd",
    ]
    for app in app_list:
        cmd = "apt purge -y %s" % app
        os.system(cmd)
    os.system("apt autoremove -y; apt autoclean -y")


def add_amazing_fonts():
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "cp -rf %s/fonts/* /usr/share/fonts/" % (current_dir)
    os.system(cmd)
    os.system("fc-cache -f -v")


def install_themes(user):
    os.system("apt install -y faenza-icon-theme")
    proc.run_as_user(user, "mkdir -p ~/.themes")
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "cp -rf %s/themes/* ~/.themes" % (current_dir)
    proc.run_as_user(user, cmd)


def init_profile(user):
    proc.run_as_user(user, "rm -rf ~/.profile")
    proc.run_as_user(user, "touch ~/.profile")


def install_filemon_tool():
    os.system("apt install -y inotify-tools watchman")


def install_tools():
    tool_list = [
        "qalculate-gtk",
        "grsync",
        "xinput",
        "gufw",
        "menulibre",
        "xfce4-screenshooter",
        "xfce4-screensaver",
        "xfce4-taskmanager",
    ]
    for tool in tool_list:
        cmd = "apt install -y %s" % tool
        os.system(cmd)


# http://localhost:631/
def install_printer_essential():
    os.system("apt install -y system-config-printer")
    os.system("apt install -y cups cups-browsed")
    os.system("systemctl enable cups-browsed --now")
    os.system("systemctl enable cups --now")


def install_browser():
    os.system("apt install -y chromium chromium-l10n")


def do_zsh_config(user):
    cmd = "usermod -s $(which zsh) %s" % (user)
    os.system(cmd)
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "sh %s/zsh/user/config.sh" % (current_dir)
    proc.run_as_user(user, cmd)


def install_key_tool():
    os.system("apt install -y seahorse")


def install_terminator(user):
    os.system("apt install -y terminator")
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "sh %s/../../development/terminal/terminator/install.sh" % (current_dir)
    proc.run_as_user(user, cmd)
    # 查询 sudo update-alternatives --config x-terminal-emulator
    os.system("update-alternatives --set x-terminal-emulator /usr/bin/terminator")


def install_modbus_tool():
    os.system("apt install -y mbpoll")


def do_vim_config(user):
    os.system("apt install -y xfce4-terminal ripgrep neovim")
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "sh %s/../../development/editor/nvim/install.sh" % (current_dir)
    proc.run_as_user(user, cmd)


def run_root_console_script(mirror_name):
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "python %s/console.py %s" % (current_dir, mirror_name)
    os.system(cmd)


def fix_translation_bug(user):
    cmd = "mkdir -p ~/.local/share/applications/"
    proc.run_as_user(user, cmd)
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "cp -rf %s/translations/* ~/.local/share/applications/" % (current_dir)
    proc.run_as_user(user, cmd)
    cmd = "update-desktop-database ~/.local/share/applications"
    proc.run_as_user(user, cmd)


def do_clean():
    os.system("apt autoremove -y; apt autoclean")


if __name__ == "__main__":
    if not proc.is_root():
        print("This program must be run as root. Aborting.")
        exit(-1)

    script_name = str(sys.argv[0])
    login_user = os.getlogin()
    if len(sys.argv) < 2:
        print("用法: %s aliyun/ustc" % script_name)
        exit(-1)

    mirror_name = str(sys.argv[1])

    add_usr_sbin_to_path_env()

    disable_pc_beep()
    make_user_dir_en(login_user)

    run_root_console_script(mirror_name)

    # gui 界面需要开启休眠支持
    enable_sleep()

    # 卸载浏览器之前，需要装一个默认浏览器，否则会给你随便装一个
    install_browser()

    init_profile(login_user)
    make_git_default_config(login_user)

    install_sudo(login_user)
    install_tools()
    install_filemon_tool()

    # 中文和主题美化
    install_chinese_fonts()
    install_fcitx(login_user)
    install_themes(login_user)
    add_amazing_fonts()

    install_color_picker()
    install_api_viewer()
    install_sniffer(login_user)
    install_vm_essential()
    install_virt_manager(login_user)
    install_pg_essential()
    install_ios_tools()
    install_power_management_tool()
    install_remote_gui_client()
    install_audio_manager()
    install_clang_llvm_lldb()
    set_dev_rules()
    install_serial_tools(login_user)
    install_printer_essential()
    install_embedded_tools()
    install_key_tool()
    install_image_viewer()
    install_login_setting()
    install_touch_board_driver()
    install_video_recorder()
    install_disk_partition_tool()
    install_unzipper()
    install_beam()
    disable_file_history(login_user)
    install_proxychains()
    install_privoxy()
    install_rt_test_tools()
    install_terminator(login_user)
    install_media_player()
    install_modbus_tool()
    install_notes_tool()
    install_pdf_reader()
    install_qt_setting_tool()
    make_xfce_ftp_support()

    do_vim_config(login_user)
    do_zsh_config(login_user)

    do_clean_after_install()
    fix_translation_bug(login_user)
    do_clean()
