#! /usr/bin/env /bin/bash

CURRENT_DIR=$(cd "$(dirname "$0")";pwd)

mkdir -p ~/.local/share/xfce4/terminal/colorschemes/
cp -rf $CURRENT_DIR/*.theme ~/.local/share/xfce4/terminal/colorschemes/