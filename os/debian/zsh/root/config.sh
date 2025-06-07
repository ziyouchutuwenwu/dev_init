#! /usr/bin/env bash

CURRENT_DIR=$(cd "$(dirname "$0")";pwd)

chsh -s $(which zsh) $USER

rm -rf ~/.zshrc
cp -rf $CURRENT_DIR/zshrc ~/.zshrc
chmod -w ~/.zshrc

# 用户级环境变量
mkdir -p ~/.local/etc/profile.d/
cp -rf $CURRENT_DIR/env/* ~/.local/etc/profile.d/

echo "apt update; apt-file update; apt upgrade -y; apt full-upgrade -y; apt autopurge -y; apt autoclean" > ~/.zsh_history
chmod -w ~/.zsh_history
