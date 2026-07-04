#!/usr/bin/env bash

tools=(
  litecli
  mycli
  pgcli
  sqlmap
  yt-dlp
)

for tool in "${tools[@]}"; do
  uv tool install -U "$tool"
done

echo "done!"
