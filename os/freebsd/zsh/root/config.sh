#!/usr/bin/env sh

CURRENT_DIR=$(cd "$(dirname "$0")";pwd)

rm -rf ~/.zshrc
cp -rf $CURRENT_DIR/zshrc ~/.zshrc
chmod -w ~/.zshrc

# 用户级环境变量
mkdir -p ~/.local/
cp -rf $CURRENT_DIR/etc ~/.local/

echo "pkg update -fq; pkg upgrade -y; pkg autoremove -y; pkg clean -ay" > ~/.zsh_history
chmod -w ~/.zsh_history
