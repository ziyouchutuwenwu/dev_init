#!/usr/bin/env /bin/bash

CURRENT_DIR=$(cd "$(dirname "$0")";pwd)

# zprofile 会导致菜单全部便英文
# 如果禁止生成会导致大更新的时候失败
rm -rf /etc/zsh/zprofile

cp -rf $CURRENT_DIR/zshenv /etc/zsh/
mkdir -p /usr/local/etc/zsh/
cp -rf $CURRENT_DIR/zsh/* /usr/local/etc/zsh
