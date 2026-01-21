#!/usr/bin/env sh

if [ "$(id -u)" -ne 0 ] ; then
    echo "need run as root" $0
    exit
fi

CURRENT_DIR=$(cd "$(dirname "$0")";pwd)

rm -rf ~/.profile
touch ~/.profile

# 加速启动
sysrc -f /boot/loader.conf.local autoboot_delay="0"

# 启用 carp
sysrc -f /boot/loader.conf.local carp_load="YES"

# 中科大的镜像似乎会有校验码错误，目前用官方加代理
# mkdir -p /usr/local/etc/pkg/repos/
#cp -rf $CURRENT_DIR/rc_files/pkg.conf /usr/local/etc/pkg/repos/
ASSUME_ALWAYS_YES=yes pkg bootstrap -f
ASSUME_ALWAYS_YES=yes pkg update -fq

# 安装预装的工具
pkg install -y axel curl aria2 git

# 暂时不放配置
pkg install -y neovim

# 开机启动
cp -rf $CURRENT_DIR/rc_files/rc.local /etc/rc.local
chmod a+x /etc/rc.local

# fetch https://mirrors.ustc.edu.cn/freebsd-ports/ports.tar.gz
# fetch https://download.freebsd.org/ports/ports/ports.tar.gz
# tar -zxvf ports.tar.gz -C /usr/
# rm ports.tar.gz
git clone --depth 1 https://git.FreeBSD.org/ports.git /usr/ports
cp -rf $CURRENT_DIR/rc_files/ports.conf /etc/make.conf

# ssh
sed -i "" 's/#PermitRootLogin no/PermitRootLogin yes/g' /etc/ssh/sshd_config
sed -i "" 's/^#X11Forwarding no/X11Forwarding yes/' /etc/ssh/sshd_config
sed -i '' -E 's/^[[:space:]]*#?GatewayPorts.*/GatewayPorts clientspecified/' /etc/ssh/sshd_config
service sshd restart

# jail 虚拟化
pkg install -y qjail
# fetch -o /tmp/ https://download.freebsd.org/releases/amd64/14.2-RELEASE/base.txz
# axel -o /tmp/ http://mirrors.ustc.edu.cn/freebsd/releases/amd64/13.0-RELEASE/base.txz

# 13.0-RELEASE
# 14.1-RELEASE-p7
RELEASE_VERSION=$(uname -r | sed 's/\(-p[0-9]*\)*$//')
ARCH=$(uname -m)
# axel -o /tmp/ http://mirrors.ustc.edu.cn/freebsd/releases/$ARCH/$RELEASE_VERSION/base.txz
fetch -o /tmp/ https://download.freebsd.org/releases/$ARCH/$RELEASE_VERSION/base.txz
qjail install -f /tmp/base.txz

mkdir -p /usr/jails/template/usr/local/etc/pkg/repos
cp -rf $CURRENT_DIR/rc_files/pkg.conf /usr/jails/template/usr/local/etc/pkg/repos/

TIME_ZONE=$(cat /var/db/zoneinfo)
cp -rf /usr/share/zoneinfo/$TIME_ZONE /usr/jails/template/etc/localtime
sed -i "" 's/#PermitRootLogin no/PermitRootLogin yes/g' /usr/jails/template/etc/ssh/sshd_config

# 常用工具
pkg install -y reptyr
pkg install -y xclip
pkg install -y fusefs-sshfs
pkg install -y autossh sshpass
pkg install -y screen
pkg install -y fastfetch
pkg install -y fd-find ripgrep
pkg install -y enca
pkg install -y tree
pkg install -y lscpu
pkg install -y duf
pkg install -y socat
pkg install -y htop
pkg install -y expect
pkg install -y binaryen

# 自动安装 nmap 的 ncat
pkg install -y nmap

# tmux
pkg install -y tmux
cp -rf $CURRENT_DIR/../../development/terminal/tmux/config/* /usr/local/etc/

# 启动加载
mkdir -p /usr/local/etc/profile.d/
cp -rf $CURRENT_DIR/profile.d/*.sh /usr/local/etc/profile.d/

# bash 无法自动加载 /etc/profile, bash -l 也不行，必须要手动 source /etc/profile
# 因此用 zsh
pkg install -y zsh
chsh -s $(which zsh) root
sh $CURRENT_DIR/zsh/global/config.sh
sh $CURRENT_DIR/zsh/root/config.sh

rm -rf ~/.history
rm -rf ~/.cshrc
rm -rf ~/.k5login
rm -rf ~/.login
rm -rf ~/.profile
rm -rf ~/.shrc
rm -rf ~/.sh_history
