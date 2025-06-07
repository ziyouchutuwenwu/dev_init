#! /usr/bin/env /bin/bash

CURRENT_DIR=$(cd "$(dirname "$0")";pwd)

chsh -s $(which zsh) $USER

git clone --depth 1 https://github.com/zdharma-continuum/zinit.git ~/.zinit/bin
rm -rf ~/.zshrc
cp -rf $CURRENT_DIR/zshrc ~/.zshrc
chmod -w ~/.zshrc

# 用户级环境变量
mkdir -p ~/.local/etc/profile.d/
cp -rf $CURRENT_DIR/env/* ~/.local/etc/profile.d/

echo "yes | yay --noconfirm -Syyu; yes | yay --noconfirm -Scc" > ~/.zsh_history
echo "zinit self-update && (zinit update && zinit delete --clean -y)" >> ~/.zsh_history
chmod -w ~/.zsh_history

rm -rf ~/.bashrc
rm -rf ~/.bash_history
rm -rf ~/.bash_logout
