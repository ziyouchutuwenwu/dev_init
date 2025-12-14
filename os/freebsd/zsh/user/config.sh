#!/usr/bin/env sh

CURRENT_DIR=$(cd "$(dirname "$0")";pwd)

git clone --depth 1 https://github.com/zdharma-continuum/zinit.git ~/.zinit/bin
rm -rf ~/.zshrc
cp -rf $CURRENT_DIR/zshrc ~/.zshrc
chmod -w ~/.zshrc

# 用户级环境变量
mkdir -p ~/.local/
cp -rf $CURRENT_DIR/etc ~/.local/

echo "sudo pkg update -fq; sudo pkg upgrade -y; sudo pkg autoremove -y; sudo pkg clean -ay" > ~/.zsh_history
echo "zinit self-update; zinit update -p -q; zinit delete --clean -y" >> ~/.zsh_history
chmod -w ~/.zsh_history
