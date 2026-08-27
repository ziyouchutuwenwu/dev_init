#!/usr/bin/env bash

CURRENT_DIR=$(cd "$(dirname "$0")";pwd)

rm -rf ~/.config/terminator
mkdir -p ~/.config/terminator

cp -rf $CURRENT_DIR/config/*  ~/.config/terminator/
echo "Install success!";