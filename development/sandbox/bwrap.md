# bwrap

## 说明

linux 下的沙盒

## 用法

idea 无限试用

```sh
mkdir -p ~/dev/java/idea_setting/config
mkdir -p ~/dev/java/idea_setting/trial
mkdir -p ~/dev/java/idea_setting/cache

bwrap --unshare-all --share-net --die-with-parent \
  --ro-bind / / \
  --tmpfs /sys --tmpfs /home --tmpfs /tmp --tmpfs /run \
  --proc /proc --dev /dev \
  \
  --ro-bind ~/.profile ~/.profile \
  --bind ~/.cache/fontconfig ~/.cache/fontconfig \
  --ro-bind ~/.Xauthority ~/.Xauthority \
  --ro-bind /tmp/.X11-unix /tmp/.X11-unix \
  --ro-bind /run/user/$UID/bus /run/user/$UID/bus \
  \
  --bind ~/dev/java/apache-maven/ ~/dev/java/apache-maven \
  --bind ~/.m2 ~/.m2 \
  --bind ~/.config/google-chrome/ ~/.config/google-chrome/ \
  --bind ~/projects/ ~/projects/ \
  --bind ~/dev/java/idea_setting/cache ~/.cache/JetBrains/IntelliJIdea2023.3/ \
  --bind ~/dev/java/idea_setting/config ~/.config/JetBrains/IntelliJIdea2023.3/ \
  --bind ~/dev/java/idea_setting/trial ~/.java/.userPrefs \
  --ro-bind ~/dev/java/idea ~/dev/java/idea \
  --new-session bash -cl ~/dev/java/idea/bin/idea.sh
```
