#! /usr/bin/env bash

CURRENT_DIR=$(cd "$(dirname "$0")";pwd)

rm -rf ~/.config/nvim
rm -rf ~/.local/share/nvim
rm -rf ~/.local/state/nvim

git clone --depth 1 https://github.com/AstroNvim/template ~/.config/nvim
mkdir -p ~/.config/nvim/lua/plugins/
cp -rf $CURRENT_DIR/lua/*.lua ~/.config/nvim/lua/plugins/

echo "Install success!";