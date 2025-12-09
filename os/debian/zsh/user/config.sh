#!/usr/bin/env /bin/bash

CURRENT_DIR=$(cd "$(dirname "$0")";pwd)

git clone --depth 1 https://github.com/zdharma-continuum/zinit.git ~/.zinit/bin
rm -rf ~/.zshrc
cp -rf $CURRENT_DIR/zshrc ~/.zshrc
chmod -w ~/.zshrc

# 用户级环境变量
mkdir -p ~/.local/
cp -rf $CURRENT_DIR/etc ~/.local/

echo "sudo apt update; sudo apt-file update; sudo apt upgrade -y; sudo apt full-upgrade -y; sudo apt autopurge -y; sudo apt autoclean" > ~/.zsh_history
echo "zinit self-update; zinit update -p -q; zinit delete --clean -y" >> ~/.zsh_history
chmod -w ~/.zsh_history

rm -rf ~/.bashrc
rm -rf ~/.bash_history
rm -rf ~/.bash_logout
