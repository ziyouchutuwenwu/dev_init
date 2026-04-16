#!/usr/bin/env bash

CURRENT_DIR=$(cd "$(dirname "$0")";pwd)

mkdir -p ~/.m2
cp $CURRENT_DIR/ali.xml ~/.m2/settings.xml
