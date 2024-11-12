#! /usr/bin/env /bin/bash

CURRENT_DIR=$(cd "$(dirname "$0")";pwd)

# 键盘映射
mkdir -p ~/.zinit/custom
cp -rf $CURRENT_DIR/zinit/keymap_rc ~/.zinit/custom/keymap_rc

git clone --depth 1 https://github.com/zdharma-continuum/zinit.git ~/.zinit/bin
rm -rf ~/.zshrc
cp -rf $CURRENT_DIR/zinit/zshrc ~/.zshrc
chmod -w ~/.zshrc

echo "yes | yay --noconfirm -Syyu; yes | yay --noconfirm -Scc" > ~/.zsh_history
echo "asdf update" >> ~/.zsh_history
echo "zinit self-update; zinit delete --clean -y; zinit update" >> ~/.zsh_history
chmod -w ~/.zsh_history

rm -rf ~/.bashrc
rm -rf ~/.bash_history
rm -rf ~/.bash_logout