#!/usr/bin/env bash

set -e

tools=(
  pip
  ansible
  stegoveritas-binwalk
  litecli
  mycli
  pgcli
  sqlmap
  scons
  you-get
  yt-dlp
  prettytable
  cython
  nuitka
)

for tool in "${tools[@]}"; do
  uv pip install --system -U "$tool" || true
done

echo "done!"
