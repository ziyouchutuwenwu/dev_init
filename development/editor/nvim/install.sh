#!/usr/bin/env bash

set -euo pipefail

CURRENT_DIR=$(cd "$(dirname "$0")";pwd)

echo "=== AstroNvim 配置安装 ==="

echo "清理旧配置..."
rm -rf ~/.config/nvim
rm -rf ~/.local/share/nvim
rm -rf ~/.local/state/nvim

echo "克隆 AstroNvim 模板..."
git clone --depth 1 https://github.com/AstroNvim/template ~/.config/nvim

echo "安装用户自定义配置..."
# 复制用户插件配置文件到 plugins/ 目录
mkdir -p ~/.config/nvim/lua/plugins/
find "$CURRENT_DIR/lua" -maxdepth 1 -name '*.lua' -exec cp -f {} ~/.config/nvim/lua/plugins/ \;

# 复制用户配置目录
cp -rf "$CURRENT_DIR/lua/user" ~/.config/nvim/lua/

echo ""
echo "✓ 安装成功！"
echo "配置路径: ~/.config/nvim"