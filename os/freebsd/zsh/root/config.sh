#! /usr/bin/env sh

CURRENT_DIR=$(cd "$(dirname "$0")";pwd)

chsh -s $(which zsh) $USER

rm -rf ~/.zshrc
cp -rf $CURRENT_DIR/zshrc ~/.zshrc
chmod -w ~/.zshrc

# 用户级环境变量
mkdir -p ~/.local/etc/profile.d/
cp -rf $CURRENT_DIR/env/* ~/.local/etc/profile.d/

echo "pkg update -fq; pkg upgrade -y; pkg autoremove -y; pkg clean -ay" > ~/.zsh_history
echo "freebsd-update fetch install" >> ~/.zsh_history
chmod -w ~/.zsh_history
