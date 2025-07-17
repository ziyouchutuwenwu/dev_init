# snmp

## 安装

```sh
sudo apt install snmp snmpd
```

修改配置

```sh
/etc/snmp/snmpd.conf
```

```sh
# 改成在所有ip监听
agentAddress udp:161,udp6[::1]:161

# 默认查看.1为开头的全部内容
view all included .1
rocommunity public default -V all
```

## 查看 cpu 等信息

```sh
snmpwalk -v 2c -c public localhost enterprises.ucdavis.systemStats
```
