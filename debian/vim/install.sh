#! /usr/bin/env /bin/bash

CURRENT_DIR=$(cd "$(dirname "$0")";pwd)

rm -rf ~/.vim
rm -rf ~/.vimrc

cp -rf $CURRENT_DIR/vim  ~/.vim
echo "Install success!";
