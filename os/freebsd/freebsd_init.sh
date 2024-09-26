#! /usr/bin/env sh

if [ "$#" -ne 1 ]; then
  echo "$0 non_root_user_name"
  exit
fi

if [ "$(id -u)" -ne 0 ] ; then
    echo "need run as root" $0
    exit
fi

USER=$1
export CURRENT_DIR=$(cd "$(dirname "$0")";pwd)

groups $USER | grep wheel > /dev/null
if [ $? -ne 0 ] ; then
  echo $USER "not in wheel group, now add"
  pw groupmod wheel -m $USER
else
  echo $USER "already in wheel group"
fi

# 不需要 gui 的服务器初始化脚本
sh $CURRENT_DIR/root_no_gui_init.sh

# 显卡
pkg install -y drm-kmod
sysrc -f /etc/rc.conf kld_list="i915kms"
# intel 集成显卡
pkg install -y xf86-video-intel
pkg install -y libva-intel-driver
pw groupmod video -m $USER

# nvidia 显卡闭源驱动
pkg install -y nvidia-driver nvidia-settings nvidia-xconfig
sysrc -f /etc/rc.conf kld_list="nvidia nvidia-modeset"
sysrc -f /etc/rc.conf linux_enable="YES"

pkg install -y xorg
pkg install -y slim
pkg install -y xfce

# 系统原来的 rc.conf 里面有内容，只能追加
sysrc -f /etc/rc.conf moused_enable="YES"
sysrc -f /etc/rc.conf hald_enable="YES"
sysrc -f /etc/rc.conf dbus_enable="YES"
sysrc -f /etc/rc.conf slim_enable="YES"

# ~/.xinitrc
USER_HOME=`su $USER -c 'echo $HOME'`
cp -rf $CURRENT_DIR/rc_files/xinitrc $USER_HOME/.xinitrc
chown $USER $USER_HOME/.xinitrc
chgrp $USER $USER_HOME/.xinitrc

# sudo
pkg install -y sudo
cp -rf $CURRENT_DIR/sudoers/* /usr/local/etc/sudoers.d/

su $USER -c 'rm -rf ~/.profile'
su $USER -c 'touch ~/.profile'

# git 全局配置
pkg install -y git
su $USER -c 'git config --global core.autocrlf false'
su $USER -c 'git config --global core.quotepath off'

# 很多脚本基于 bash, 所以安装
pkg install -y bash

# 中文和输入法
pkg install -y wqy-fonts
pkg install -y fcitx5 fcitx5-configtool
pkg install -y zh-fcitx5-chinese-addons
su $USER -c 'mkdir -p ~/.config/fcitx5/'
su $USER -c 'cp -rf $CURRENT_DIR/fcitx/config/* ~/.config/fcitx5/'
su $USER -c 'mkdir -p ~/.local/share/fcitx5/themes/'
su $USER -c 'cp -rf $CURRENT_DIR/fcitx/themes/* ~/.local/share/fcitx5/themes/'
su $USER -c 'mkdir -p ~/.config/autostart'
su $USER -c 'ln -s /usr/local/share/applications/org.fcitx.Fcitx5.desktop ~/.config/autostart/'

su $USER -c 'cp -rf $CURRENT_DIR/rc_files/xinitrc ~/.xinitrc'

mkdir -p /usr/local/share/fonts/
cp -rf $CURRENT_DIR/fonts/* /usr/local/share/fonts/
fc-cache -f -v

# wezterm
pkg install -y wezterm
su $USER -c 'sh $CURRENT_DIR/../../development/wezterm/install.sh'

# terminator
pkg install -y terminator
su $USER -c 'mkdir -p ~/.config/terminator/'
su $USER -c 'cp -rf $CURRENT_DIR/../../development/terminator/config ~/.config/terminator/'

pkg install -y gnome-icons-faenza
su $USER -c 'sh $CURRENT_DIR/themes/install.sh'
su $USER -c 'rm -rf ~/.local/share/recently-used.xbel'
su $USER -c 'mkdir -p ~/.local/share/recently-used.xbel'

pkg install -y wireshark
echo 'own  bpf* root:network' > /etc/devfs.conf
echo 'perm bpf* 0660' >> /etc/devfs.conf

pkg install -y networkmgr
pkg install -y chromium
pkg install -y qalculate-gtk
pkg install -y xarchiver
pkg install -y thunar-archive-plugin
pkg install -y qt5ct
pkg install -y vlc smplayer
pkg install -y audacious-plugins pavucontrol
pkg install -y xfce4-screenshooter-plugin
pkg install -y scrcpy
pkg install -y fusefs-ifuse
pkg install -y upx

su $USER -c 'mkdir -p ~/desktop'
su $USER -c 'rm -rf ~/Desktop'
su $USER -c 'mkdir -p ~/.templates'
su $USER -c 'cp -rf $CURRENT_DIR/englih_user_dir/user-dirs.dirs ~/.config/'

# neovim
pkg install -y xfce4-terminal ripgrep xclip neovim wget
su $USER -c 'sh $CURRENT_DIR/../../development/editor/nvim/install.sh'

pkg install -y privoxy
cp -rf $CURRENT_DIR/../../development/proxy/privoxy/config /usr/local/etc/privoxy/config
sysrc -f /etc/rc.conf privoxy_enable="YES"

# qemu 下鼠标支持
pkg install -y utouch-kmod
echo 'utouch_load="YES"' >> /boot/loader.conf

pkg install -y python
# pkg install -y py39-pip

# erlang
pkg install -y erlang rebar3
pkg install -y elixir inotify-tools

su $USER -c 'python $CURRENT_DIR/../../development/asdf/asdf_init.py'

chsh -s $(which zsh) $USER
su $USER -c 'sh $CURRENT_DIR/zsh/config.sh'

# 处理桌面图标的问题
su $USER -c 'mkdir -p ~/.local/share/applications/'
su $USER -c 'cp -rf $CURRENT_DIR/translations/* ~/.local/share/applications/'
