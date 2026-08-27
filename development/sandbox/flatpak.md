# flatpak

## 说明

基于沙盒

## 用法

```sh
flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
```

```sh
flatpak install --user -y flathub com.github.tchx84.Flatseal
flatpak install --user -y flathub com.dingtalk.DingTalk
flatpak install --user -y flathub com.wps.Office
flatpak install --user -y flathub com.tencent.WeChat
```

```sh
flatpak run com.github.tchx84.Flatseal
flatpak run com.dingtalk.DingTalk
flatpak run com.wps.Office
flatpak run com.tencent.WeChat
```
