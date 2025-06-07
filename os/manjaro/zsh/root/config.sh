#! /usr/bin/env /bin/bash

CURRENT_DIR=$(cd "$(dirname "$0")";pwd)

chsh -s $(which zsh) $USER

rm -rf ~/.zshrc
cp -rf $CURRENT_DIR/zshrc ~/.zshrc
chmod -w ~/.zshrc

# 用户级环境变量
mkdir -p ~/.local/etc/profile.d/
cp -rf $CURRENT_DIR/env/* ~/.local/etc/profile.d/

echo "yes | pacman --noconfirm -Syyu; yes | pacman --noconfirm -Scc" > ~/.zsh_history
chmod -w ~/.zsh_history