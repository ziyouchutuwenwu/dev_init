#!/usr/bin/env sh

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
sh $CURRENT_DIR/console.sh

# 显卡
pkg install -y drm-kmod
sysrc -f /etc/rc.conf.local kld_list="i915kms"

# 自带 modesetting 驱动，更加现代
# 这个用来硬解码
pkg install -y libva-intel-driver
pw groupmod video -m $USER

# lightdm 在登录的时候，会有一个很诡异的用户，非常丑，所以换掉
pkg install -y slim
pkg install -y xorg
pkg install -y xfce
pkg install -y xfce4-session

# cli 下禁用鼠标
sysrc -f /etc/rc.conf.local moused_enable="NO"
sysrc -f /etc/rc.conf.local moused_nondefault_enable="NO"

sysrc -f /etc/rc.conf.local dbus_enable="YES"
sysrc -f /etc/rc.conf.local slim_enable="YES"

# ~/.xinitrc
USER_HOME=$(su $USER -c 'echo $HOME')
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
sed -i "" 's/#export LANG=zh_CN.UTF-8/export LANG=zh_CN.UTF-8/g' /usr/local/etc/profile.d/lang.sh
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

# terminator
pkg install -y terminator
su $USER -c 'sh $CURRENT_DIR/../../development/terminal/terminator/install.sh'

pkg install -y gnome-icons-faenza
su $USER -c 'sh $CURRENT_DIR/themes/install.sh'
su $USER -c 'rm -rf ~/.local/share/recently-used.xbel'
su $USER -c 'mkdir -p ~/.local/share/recently-used.xbel'

pkg install -y wireshark
echo 'own  bpf* root:network' > /etc/devfs.conf
echo 'perm bpf* 0660' >> /etc/devfs.conf

# 不然东西太少
pkg install -y xfce4-goodies
pkg remove -y xfburn
pkg remove -y xfce4-dashboard
pkg remove -y gigolo

pkg install -y networkmgr
pkg install -y chromium
pkg install -y qalculate-gtk
pkg install -y xarchiver
pkg install -y thunar-archive-plugin

# vlc 用 qt5ct
# vlc 用 qt6ct
pkg install -y qt5ct qt6ct
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

pkg install -y xfce4-terminal ripgrep wget freerdp

# neovim
su $USER -c 'sh $CURRENT_DIR/../../development/editor/nvim/install.sh'

# qemu 下鼠标支持
pkg install -y utouch-kmod
sysrc -f /boot/loader.conf.local utouch_load="YES"

# python
pkg install -y uv

# erlang
pkg install -y erlang rebar3
pkg install -y elixir inotify-tools

chsh -s $(which zsh) $USER
su $USER -c 'sh $CURRENT_DIR/zsh/user/config.sh'

# 处理桌面图标的问题
su $USER -c 'mkdir -p ~/.local/share/applications/'
su $USER -c 'cp -rf $CURRENT_DIR/translations/* ~/.local/share/applications/'
# ~/.local/share/applications 下，把 hidden 目录里面的每个文件，在 ~/.local/share/applications 下创建一个快捷方式
su $USER -c 'cd ~/.local/share/applications && for f in hidden/*; do ln -s "$f" .; done'
su $USER -c 'update-desktop-database ~/.local/share/applications'
