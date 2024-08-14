#! /usr/bin/env sh

if [ "$(id -u)" -ne 0 ] ; then
    echo "need run as root" $0
    exit
fi

CURRENT_DIR=$(cd "$(dirname "$0")";pwd)

mkdir -p /usr/local/etc/pkg/repos/
cp -rf $CURRENT_DIR/rc_files/pkg.conf /usr/local/etc/pkg/repos/
ASSUME_ALWAYS_YES=yes pkg update -fq

# 安装预装的工具
pkg install -y axel curl aria2 git

# 历史记录部分
echo "pkg update -fq; pkg upgrade -y; pkg autoremove -y; pkg clean -y; freebsd-update fetch install" > ~/.history
chmod -w ~/.history

# 暂时不放配置
pkg install -y neovim

# 开机启动
cp -rf $CURRENT_DIR/rc_files/rc.local /etc/rc.local
chmod +x /etc/rc.local

fetch https://mirrors.ustc.edu.cn/freebsd-ports/ports.tar.gz
tar -zxvf ports.tar.gz -C /usr/ports
rm ports.tar.gz
cp -rf $CURRENT_DIR/rc_files/ports.conf /etc/make.conf

# update 源
# sed -i "" 's#update.FreeBSD.org#update.freebsd.cn#g' /etc/freebsd-update.conf

# ssh 允许 root 登录
sed -i "" 's/#PermitRootLogin no/PermitRootLogin yes/g' /etc/ssh/sshd_config
service sshd restart

# jail 虚拟化
pkg install -y qjail
# axel -o /tmp/ http://mirrors.ustc.edu.cn/freebsd/releases/amd64/13.0-RELEASE/base.txz
axel -o /tmp/ http://mirrors.ustc.edu.cn/freebsd/releases/`uname -m`/`uname -r`/base.txz
qjail install -f /tmp/base.txz

mkdir -p /usr/jails/template/usr/local/etc/pkg/repos
cp -rf $CURRENT_DIR/rc_files/pkg.conf /usr/jails/template/usr/local/etc/pkg/repos/
cp -rf /usr/share/zoneinfo/`cat /var/db/zoneinfo` /usr/jails/template/etc/localtime
# sed -i "" 's#update.FreeBSD.org#update.freebsd.cn#g' /usr/jails/template/etc/freebsd-update.conf
sed -i "" 's/#PermitRootLogin no/PermitRootLogin yes/g' /usr/jails/template/etc/ssh/sshd_config

# 常用工具
pkg install -y cmatrix cowsay
pkg install -y fusefs-sshfs
pkg install -y autossh sshpass
pkg install -y screen
pkg install -y zellij
pkg install -y the_silver_searcher
pkg install -y tree
pkg install -y lscpu
pkg install -y duf
pkg install -y socat
pkg install -y htop
pkg install -y expect
pkg install -y netcat
pkg install -y nmap
pkg install -y rinetd

pkg install -y zsh
chsh -s $(which zsh) $(whoami)
cp -rf $CURRENT_DIR/zsh/zshenv /usr/local/etc/zshenv

# 启动加载
mkdir -p /usr/local/etc/profile.d/
cp -rf $CURRENT_DIR/profile.d/*.sh /usr/local/etc/profile.d/
chmod +x /usr/local/etc/profile.d/*.sh
