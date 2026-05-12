#!/usr/bin/env bash

CURRENT_DIR=$(cd "$(dirname "$0")";pwd)

mkdir -p ~/.agents/skills/
cp -rf $CURRENT_DIR/proxy-auto ~/.agents/skills/

echo "Install success!";