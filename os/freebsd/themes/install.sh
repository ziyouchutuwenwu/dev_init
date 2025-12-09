#!/usr/bin/env bash

CURRENT_DIR=$(cd "$(dirname "$0")";pwd)

mkdir -p ~/.themes
cp -rf $CURRENT_DIR/* ~/.themes/