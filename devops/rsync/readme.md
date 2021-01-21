# rsync 同步备份说明

iptables 设置全部允许

```sh
sudo iptables -P INPUT ACCEPT; sudo iptables -P OUTPUT ACCEPT; sudo iptables -P FORWARD ACCEPT
```

备份机，执行脚本备份

```sh
rsync -azP --delete mmc@ip:/home/xxx/dev ./
```
