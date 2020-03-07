#! /usr/bin/env /bin/bash

CURRENT_DIR=$(cd "$(dirname "$0")";pwd)

rm -rf ~/.vim
rm -rf ~/.vimrc

mkdir -p ~/.vim/colors
cp $CURRENT_DIR/solarized.vim ~/.vim/colors/

cp $CURRENT_DIR/_vimrc  ~/.vimrc
echo "Install success!";