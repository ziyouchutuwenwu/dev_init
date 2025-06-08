#! /usr/bin/env bash

CURRENT_DIR=$(cd "$(dirname "$0")";pwd)

rm -rf ~/.config/uv
mkdir -p ~/.config/uv
cp -rf $CURRENT_DIR/*.toml ~/.config/uv/

echo "done";
