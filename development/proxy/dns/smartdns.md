# smartdns

## 用法

### 准备

```sh
sudo mkdir -p /usr/local/etc/smartdns/
```

### 配置

smartdns.conf

```conf
# log
log-level debug
log-file /var/log/smartdns.log

# 装 virt-manager 的话
# sudo systemctl stop dnsmasq
# sudo systemctl disable dnsmasq
# sudo lsof -i :53
bind 0.0.0.0:53

# 优化
cache-size 512
prefetch-domain yes
dualstack-ip-selection yes
response-mode fastest-ip

# 公司
server 192.168.9.253 -group office

# 国内
server 223.6.6.6 -group china
server-tls tls://dns.alidns.com -group china

# doh 写法1
# server 8.8.8.8 -bootstrap-dns
# server-https https://dns.google/dns-query -group oversea

# doh 写法2
#server-https https://dns.google/dns-query -host-name dns.google -ip 8.8.8.8 -group oversea
#server-https https://cloudflare-dns.com/dns-query -host-name cloudflare-dns.com -ip 1.1.1.1 -group oversea

server-https https://120.53.53.53/dns-query -group oversea
server-https https://doh.360.cn/dns-query -group oversea
server-https https://dns.alidns.com/dns-query -group oversea
server-https https://doh.pub/dns-query -group oversea

# 规则
domain-rules *.xxx.com -nameserver office

domain-set -name whitelist -file whitelist.txt
domain-rules /domain-set:whitelist/ -nameserver oversea

# 黑名单
conf-file blacklist.txt

# 默认
nameserver /./ china
```

whitelist.txt

```txt
*.github.com
*.microsoft.com
*.apple.com
*.googleapis.com
```

blacklist.txt

```txt
address /aaa.com/#
```

### 运行

```sh
sudo smartdns -c /usr/local/etc/smartdns/smartdns.conf
```

### 验证

```sh
dig @127.0.0.1 -p 53 github.com
nslookup -port=53 github.com 127.0.0.1
```
