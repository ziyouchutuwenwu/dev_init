#!/usr/bin/env bash

set -euo pipefail

CURRENT_DIR=$(cd "$(dirname "$0")";pwd)

rm -rf ~/.config/nvim
rm -rf ~/.local/share/nvim
rm -rf ~/.local/state/nvim

echo "cloning astronvim template..."
git clone --depth 1 https://github.com/AstroNvim/template ~/.config/nvim

echo "installing plugins and configurations (core, modules, plugins)..."
mkdir -p ~/.config/nvim/lua/plugins/
cp -rf "$CURRENT_DIR/lua/"* ~/.config/nvim/lua/plugins/

echo "install done!"
