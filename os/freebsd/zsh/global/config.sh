#! /usr/bin/env sh

CURRENT_DIR=$(cd "$(dirname "$0")";pwd)

mkdir -p /usr/local/etc/zsh/
cp -rf $CURRENT_DIR/zshenv /usr/local/etc/
cp -rf $CURRENT_DIR/zsh/* /usr/local/etc/zsh

echo "pkg update -fq; pkg upgrade -y; pkg autoremove -y; pkg clean -ay" > ~/.zsh_history
echo "freebsd-update fetch install" >> ~/.zsh_history
chmod -w ~/.zsh_history
