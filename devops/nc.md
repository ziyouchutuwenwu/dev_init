# nc

## 本地监听端口

本地监听 tcp 端口

```sh
nc -l -p port
```

本地监听 udp 端口

```sh
nc -lu -p port
```

## 检测远程端口是否通

检测 tcp 端口

```sh
nc -vz ip port
```

检测 udp 端口是否通

```sh
nc -uvz ip port
```
