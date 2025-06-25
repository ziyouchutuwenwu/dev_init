#! /usr/bin/env bash

CURRENT_DIR=$(cd "$(dirname "$0")";pwd)

chsh -s $(which zsh) $USER

cp -rf $CURRENT_DIR/zshenv /etc/zsh/
mkdir -p /usr/local/etc/zsh/
cp -rf $CURRENT_DIR/zsh/* /usr/local/etc/zsh