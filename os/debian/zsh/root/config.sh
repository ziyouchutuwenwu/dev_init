#!/usr/bin/env bash

CURRENT_DIR=$(cd "$(dirname "$0")";pwd)

rm -rf ~/.zshrc
cp -rf $CURRENT_DIR/zshrc ~/.zshrc
chmod -w ~/.zshrc

# 用户级环境变量
mkdir -p ~/.local/
cp -rf $CURRENT_DIR/etc ~/.local/

echo "apt update; apt-file update; apt upgrade -y; apt full-upgrade -y; apt autopurge -y; apt autoclean" > ~/.zsh_history
chmod -w ~/.zsh_history
