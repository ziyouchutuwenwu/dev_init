#! /usr/bin/env bash

CURRENT_DIR=$(cd "$(dirname "$0")";pwd)

rm -rf ~/.config/nvim
rm -rf  ~/.local/share/nvim

mkdir -p ~/.config/nvim
cp -rf $CURRENT_DIR/config/*  ~/.config/nvim
echo "Install success!";
