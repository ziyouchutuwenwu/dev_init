#! /usr/bin/env /bin/bash

CURRENT_DIR=$(cd "$(dirname "$0")";pwd)
cp $CURRENT_DIR/20-allow-hibernate.pkla /etc/polkit-1/localauthority/50-local.d/