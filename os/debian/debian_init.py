#!/usr/bin/env python
# -*- coding: UTF-8 -*-


import os
import sys


pwd = os.path.dirname(os.path.abspath(__file__))
module_path = "%s/../../" % pwd
sys.path.append(module_path)
from py_mods import proc
from py_mods import file


# 不同的脚本都需要定义，否则会出现错误
def add_usr_sbin_to_path_env():
    os.environ["PATH"] += ":/usr/sbin/"


def update_sudo_passwd_template(pwd):
    sudo_passwd_template = "/tmp/pass.sh"
    os.system("rm -rf %s" % sudo_passwd_template)
    os.system("touch %s" % sudo_passwd_template)
    os.system("chmod a+x %s" % sudo_passwd_template)
    file.set_to_file(sudo_passwd_template, "'#! /bin/bash'")
    file.set_to_file(sudo_passwd_template, "echo %s" % pwd)


def remove_sudo_passwd_template():
    sudo_passwd_template = "/tmp/pass.sh"
    os.system("rm -rf %s" % sudo_passwd_template)


def enable_sleep():
    # 自定义的配置文件内禁用了 sleep
    cmd = "rm -rf /etc/systemd/sleep.conf.d"
    os.system(cmd)


def install_beam():
    os.system("apt install -y erlang rebar3 elixir")
    os.system("apt pyrge -y erlang-jinterface")


def install_sudo(user):
    os.system("apt install -y sudo")
    cmd = "gpasswd -a %s sudo" % user
    os.system(cmd)


def install_rt_test_tools():
    os.system("apt install -y stress rt-tests")


def install_embedded_tools():
    os.system("apt install -y openocd")
    os.system("apt install -y gdb gdbserver gdb-multiarch")
    os.system("apt install -y gcc-arm-linux-gnueabi gcc-arm-none-eabi gcc-arm-linux-gnueabihf")
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
    cmd = "cp -rf %s/../../development/proxy/proxychains/proxychains.conf /etc/proxychains4.conf" % (current_dir)
    os.system(cmd)


def install_privoxy():
    os.system("apt install -y privoxy")
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "cp -rf %s/../../development/proxy/privoxy/config /etc/privoxy/config" % (current_dir)
    os.system(cmd)
    os.system("systemctl daemon-reload; systemctl enable privoxy")


def disable_pc_beep():
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "cp -rf %s/mod_blacklist/blacklist.conf /etc/modprobe.d/" % (current_dir)
    os.system(cmd)


def englishization_user_dir_name(user):
    proc.run_as_user(user, "mkdir -p ~/desktop")
    proc.run_as_user(user, "mv ~/桌面 ~/desktop > /dev/null 2>&1")
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "cp -rf %s/englih_user_dir/user-dirs.dirs ~/.config/" % (current_dir)
    proc.run_as_user(user, cmd)
    proc.run_as_user(user, "mkdir -p ~/.templates")


def rm_unused_menu(user):
    proc.run_as_user(user, "rm -rf ~/.local/share/applications/*.wine")


def make_git_default_config(user):
    proc.run_as_user(user, "git config --global core.autocrlf false")
    proc.run_as_user(user, "git config --global core.quotepath off")


def install_color_picker():
    os.system("apt install -y kcolorchooser")


def install_api_viewer():
    os.system("apt install -y zeal")


def install_serial_tools():
    os.system("apt install -y picocom lrzsz")
    os.system("apt install -y tio")
    os.system("apt install -y gtkterm cutecom")


def install_net_capture_tools(user):
    os.system('echo "wireshark-common wireshark-common/install-setuid boolean true" | debconf-set-selections')
    os.system("apt install -y wireshark")
    cmd = "usermod -a -G wireshark %s" % user
    os.system(cmd)


def install_virt_manager(user):
    os.system("apt install -y virt-manager")
    os.system("apt purge -y virt-viewer")
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
    # 虚拟机装，剪贴板共享程序
    os.system("apt install -y spice-vdagent")
    cmd = "usermod -a -G libvirt %s" % user
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


def set_peripheral_permission():
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "cp -rf %s/peripheral_permission/* /etc/udev/rules.d/" % (current_dir)
    os.system(cmd)
    cmd = "sh %s/peripheral_permission/reload_rules.sh" % (current_dir)
    os.system(cmd)


def install_chinese_fonts():
    os.system("apt install -y xfonts-intl-chinese fonts-wqy-microhei fonts-wqy-zenhei xfonts-wqy")


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
        "imagemagic*",
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


def install_ui_useful_tools():
    tool_list = [
        "qalculate-gtk",
        "grsync",
        "xfce4-screenshooter",
        "xinput",
        "screenfetch",
        "gufw",
        "menulibre",
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
    os.system("apt install -y zsh")
    cmd = "chsh -s $(which zsh) %s" % user
    os.system(cmd)
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "sh %s/zsh/config.sh" % (current_dir)
    proc.run_as_user(user, cmd)
    cmd = "cp -rf %s/zsh/zshenv /etc/zsh/zshenv" % (current_dir)
    os.system(cmd)


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
    os.system("apt install -y xfce4-terminal ripgrep xclip neovim")
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "sh %s/../../development/editor/nvim/install.sh" % (current_dir)
    proc.run_as_user(user, cmd)


def grant_user_docker_permission(user):
    cmd = "usermod -a -G docker %s" % user
    os.system(cmd)


def run_root_no_gui_init_script(mirror_name):
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "python %s/root_no_gui_init.py %s" % (current_dir, mirror_name)
    os.system(cmd)


def fix_translation_bug(user):
    cmd = "mkdir -p ~/.local/share/applications/"
    proc.run_as_user(user, cmd)
    current_dir = os.path.dirname(os.path.abspath(__file__))
    cmd = "cp -rf %s/translations/* ~/.local/share/applications/" % (current_dir)
    proc.run_as_user(user, cmd)


if __name__ == "__main__":
    if False == proc.is_root():
        print("This program must be run as root. Aborting.")
        exit(-1)

    script_name = str(sys.argv[0])
    login_user = os.getlogin()
    if len(sys.argv) < 3:
        print("用法: %s aliyun/ustc %s的密码" % (script_name, login_user))
        exit(-1)

    mirror_name = str(sys.argv[1])
    login_pwd = str(sys.argv[2])

    add_usr_sbin_to_path_env()

    update_sudo_passwd_template(login_pwd)
    disable_pc_beep()
    englishization_user_dir_name(login_user)

    run_root_no_gui_init_script(mirror_name)

    # gui 界面需要开启休眠支持
    enable_sleep()

    # 卸载浏览器之前，需要装一个默认浏览器，否则会给你随便装一个
    install_browser()

    init_profile(login_user)
    make_git_default_config(login_user)

    install_sudo(login_user)
    install_ui_useful_tools()
    grant_user_docker_permission(login_user)

    # 中文和主题美化
    install_chinese_fonts()
    install_fcitx(login_user)
    install_themes(login_user)
    add_amazing_fonts()

    install_color_picker()
    install_api_viewer()
    install_net_capture_tools(login_user)
    install_virt_manager(login_user)
    install_pg_essential()
    install_ios_tools()
    install_power_management_tool()
    install_remote_gui_client()
    install_audio_manager()
    install_clang_llvm_lldb()
    install_serial_tools()
    install_printer_essential()
    set_peripheral_permission()
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

    rm_unused_menu(login_user)
    fix_translation_bug(login_user)
    remove_sudo_passwd_template()
