# bwrap

## 说明

linux 下的沙盒

## 用法

idea 无限试用

```sh
mkdir -p ~/dev/java/idea_config

bwrap --unshare-all --share-net --die-with-parent \
  --ro-bind / / \
  --tmpfs /sys --tmpfs /home --tmpfs /tmp --tmpfs /run \
  --proc /proc --dev /dev \
  --bind ~/.cache/fontconfig ~/.cache/fontconfig \
  --ro-bind ~/.Xauthority ~/.Xauthority \
  --ro-bind /tmp/.X11-unix /tmp/.X11-unix \
  --ro-bind /run/user/$UID/bus /run/user/$UID/bus \
  --ro-bind ~/.config/google-chrome/ ~/.config/google-chrome/ \
  --bind ~/dev/java/idea_config ~/.config/JetBrains/IntelliJIdea2023.3/ \
  --ro-bind ~/dev/java/idea ~/dev/java/idea \
  --new-session bash -cl ~/dev/java/idea/bin/idea.sh
```
