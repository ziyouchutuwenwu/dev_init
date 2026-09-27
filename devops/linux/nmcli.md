# nmcli

## 说明

命令行下配置网络

## 用法

开启 wifi

```sh
nmcli radio wifi on
```

wifi 扫描

```sh
nmcli device wifi list
```

连接，并且会生成一份名字为 xxxxxxxx 的配置

```sh
nmcli device wifi connect xxxxxxxx password 31415926
```

查看

```sh
nmcli connection show
```

修改配置

```sh
nmcli connection modify xxxxxxxx ipv4.addresses 192.168.88.100/24 ipv4.gateway 192.168.88.1 ipv4.dns "192.168.88.1" ipv4.method manual
```

加载配置

```sh
nmcli connection up xxxxxxxx
```
