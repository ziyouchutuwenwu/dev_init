# gui

## 说明

远程 ssh 执行 gui,在本地显示

## 步骤

远程机器

```sh
# linux
sed -i 's/^#X11Forwarding no/X11Forwarding yes/' /etc/ssh/sshd_config

# freebsd
sed -i "" 's/^#X11Forwarding no/X11Forwarding yes/' /etc/ssh/sshd_config
```

本地

```sh
ssh -YC xxx@xx.xx.xx.xx
```
