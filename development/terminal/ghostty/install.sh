#!/usr/bin/env bash

CURRENT_DIR=$(cd "$(dirname "$0")";pwd)

rm -rf ~/.config/ghostty
mkdir -p ~/.config/ghostty

cp -rf $CURRENT_DIR/config/*  ~/.config/ghostty/
echo "Install success!";
