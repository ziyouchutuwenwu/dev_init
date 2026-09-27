#!/usr/bin/env sh

CURRENT_DIR=$(cd "$(dirname "$0")";pwd)

mkdir -p /usr/local/etc/zsh/
cp -rf $CURRENT_DIR/zshenv /usr/local/etc/
cp -rf $CURRENT_DIR/zsh/* /usr/local/etc/zsh