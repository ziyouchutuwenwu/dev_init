#! /usr/bin/env bash

CURRENT_DIR=$(cd "$(dirname "$0")";pwd)

# 键盘映射
mkdir -p ~/.zinit/custom
cp -rf $CURRENT_DIR/zinit/keymap_rc ~/.zinit/custom/keymap_rc

git clone --depth 1 https://github.com/zdharma-continuum/zinit.git ~/.zinit/bin
rm -rf ~/.zshrc
cp -rf $CURRENT_DIR/zinit/zshrc ~/.zshrc
chmod -w ~/.zshrc

echo "sudo pkg update -fq; sudo pkg upgrade -y; sudo pkg autoremove -y; sudo pkg clean -y; sudo freebsd-update fetch install" > ~/.zsh_history
echo "asdf update" >> ~/.zsh_history
echo "zinit delete --clean -y; zinit self-update; zinit update" >> ~/.zsh_history
chmod -w ~/.zsh_history

rm -rf ~/.bashrc
rm -rf ~/.bash_history
rm -rf ~/.bash_logout
