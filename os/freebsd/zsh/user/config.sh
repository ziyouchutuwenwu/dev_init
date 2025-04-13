#! /usr/bin/env bash

CURRENT_DIR=$(cd "$(dirname "$0")";pwd)

git clone --depth 1 https://github.com/zdharma-continuum/zinit.git ~/.zinit/bin
rm -rf ~/.zshrc
cp -rf $CURRENT_DIR/zshrc ~/.zshrc
chmod -w ~/.zshrc

echo "sudo pkg update -fq; sudo pkg upgrade -y; sudo pkg autoremove -y; sudo pkg clean -ay" > ~/.zsh_history
echo "zinit self-update; zinit delete --clean -y; zinit update" >> ~/.zsh_history
echo "sudo freebsd-update fetch install" >> ~/.zsh_history
chmod -w ~/.zsh_history