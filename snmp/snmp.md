# snmp

## 安装

```bash
sudo apt install snmp snmpd
```

修改配置

```bash
vim /etc/snmp/snmpd.conf
```

```bash
# 改成在所有ip监听
agentAddress udp:161,udp6[::1]:161

# 默认查看.1为开头的全部内容
view all included .1
rocommunity public default -V all
```

## 查看 cpu 等信息

```bash
snmpwalk -v 2c -c public localhost enterprises.ucdavis.systemStats
```
