#! /usr/bin/env bash

CURRENT_DIR=$(cd "$(dirname "$0")";pwd)

rm -rf ~/.config/wezterm
mkdir -p ~/.config/wezterm

cp -rf $CURRENT_DIR/config/*  ~/.config/wezterm/
echo "Install success!";