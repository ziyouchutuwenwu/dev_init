#!/usr/bin/env bash

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
  uv tool install -U "$tool"
done

echo "done!"
