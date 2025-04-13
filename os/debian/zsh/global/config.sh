#! /usr/bin/env bash

CURRENT_DIR=$(cd "$(dirname "$0")";pwd)

cp -rf $CURRENT_DIR/zshenv /etc/

mkdir -p /usr/local/etc/zsh/
cp -rf $CURRENT_DIR/zsh/* /usr/local/etc/zsh

echo "apt update; apt-file update; apt upgrade -y; apt full-upgrade -y; apt autopurge -y; apt autoclean" > ~/.zsh_history
chmod -w ~/.zsh_history