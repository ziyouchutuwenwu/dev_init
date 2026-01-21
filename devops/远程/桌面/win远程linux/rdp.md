# rdp

## 说明

使用微软的远程工具连接

## 配置

manjaro 为例

```sh
echo "Updating system..."
sudo pacman -Syu

echo "Installing xrdp and xorgxrdp-git..."
sudo pacman -Sy yay base-devel xorg-xserver-devel
yay -S xrdp xorgxrdp

echo "Configuring Xwrapper..."
echo "allowed_users=anybody" | sudo tee -a /etc/X11/Xwrapper.config

echo "Configuring .xinitrc..."
sed -i 's/^\(SESSION=${1:-xfce-session}\)$/#\1 # original\nSESSION=${1:-xfce4-session}/' ~/.xinitrc
sed -i 's/^\s*\(local dbus_args=(--sh-syntax --exit-with-session)\)$/#\1 # original\nlocal dbus_args=(--sh-syntax)/' ~/.xinitrc
sed -i 's/^\(exec $(get_session "$1")\)$/#\1 # original\nexec $(get_session "$SESSION")/' ~/.xinitrc

echo "Enabling xrdp service..."
sudo systemctl enable --now xrdp.service
```
