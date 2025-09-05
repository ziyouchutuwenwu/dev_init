#!/usr/bin/env bash

set -e

tools=(
  ansible-core
  litecli
  mycli
  pgcli
  sqlmap
  scons
  you-get
  yt-dlp
  cython
  nuitka
)

for tool in "${tools[@]}"; do
  uv tool install -U "$tool" || true
done

echo "done!"