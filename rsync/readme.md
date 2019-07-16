- iptables设置全部允许
```
sudo iptables -P INPUT ACCEPT; sudo iptables -P OUTPUT ACCEPT; sudo iptables -P FORWARD ACCEPT
```

- 备份机，执行脚本备份
```
rsync -azP --delete mmc@ip:/home/xxx/dev ./
```