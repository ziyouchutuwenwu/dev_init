#! /usr/bin/env bash

CURRENT_DIR=$(cd "$(dirname "$0")";pwd)

mkdir -p ~/.gradle
cp $CURRENT_DIR/ali.gradle ~/.m2/init.gradle
