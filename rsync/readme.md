- iptables设置全部允许
```
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
iptables -P FORWARD ACCEPT
```

- 备份机，执行脚本备份
```
rsync -azP --delete mmc@ip:/home/xxx/dev ./
```