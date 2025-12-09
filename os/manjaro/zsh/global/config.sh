#!/usr/bin/env /bin/bash

CURRENT_DIR=$(cd "$(dirname "$0")";pwd)

# 禁止生成 zprofile, 否则会导致菜单全部便英文
rm -rf /etc/zsh/zprofile; mkdir -p /etc/zsh/zprofile

cp -rf $CURRENT_DIR/zshenv /etc/zsh/
mkdir -p /usr/local/etc/zsh/
cp -rf $CURRENT_DIR/zsh/* /usr/local/etc/zsh
