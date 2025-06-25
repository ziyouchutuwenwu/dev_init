# sshass

## 用法

```sh
sshpass -p "root123456" scp -o "StrictHostKeyChecking no" ./cri-dockerd_0.2.5.3-0.debian-bullseye_amd64.deb root@192.168.56.44:/opt/
```

```sh
sshpass -p "root123456" ssh -o "StrictHostKeyChecking no" root@192.168.56.44 "ifconfig"
```

## 注意

- sshpass 结合 ssh 的话，可以使用密码

- 配合 autossh 会弹出密码输入框，不推荐

- 如果服务器已经可以免密登陆，这里密码直接置空即可
