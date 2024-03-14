#! /usr/bin/env bash

CURRENT_DIR=$(cd "$(dirname "$0")";pwd)

rm -rf ~/.config/emacs
rm -rf  ~/.emacs.d

mkdir -p ~/.config/emacs
mkdir -p ~/.emacs.d

cp -rf $CURRENT_DIR/config/*.el  ~/.emacs.d/
cp -rf $CURRENT_DIR/config/package ~/.config/emacs/
cp -rf $CURRENT_DIR/config/settings/* ~/.config/emacs/

echo "Install success!";
