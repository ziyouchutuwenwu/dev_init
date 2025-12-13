#!/usr/bin/env bash

CURRENT_DIR=$(cd "$(dirname "$0")";pwd)

rm -rf ~/.config/tmux
mkdir -p ~/.config/tmux

cp -rf $CURRENT_DIR/config/*  ~/.config/tmux/
echo "Install success!";