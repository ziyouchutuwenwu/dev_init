#!/usr/bin/env bash

set -euo pipefail

CURRENT_DIR=$(cd "$(dirname "$0")";pwd)

rm -rf ~/.config/nvim
rm -rf ~/.local/share/nvim
rm -rf ~/.local/state/nvim

git clone --depth 1 https://github.com/AstroNvim/template ~/.config/nvim

mkdir -p ~/.config/nvim/lua/plugins/
find "$CURRENT_DIR/lua" -maxdepth 1 -name '*.lua' -exec cp -f {} ~/.config/nvim/lua/plugins/ \;

cp -rf "$CURRENT_DIR/lua/user" ~/.config/nvim/lua/

echo "install done!"