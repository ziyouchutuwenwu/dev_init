# mosdns

## 说明

<https://github.com/IrineSistiana/mosdns>

## 步骤

### 设置本地 dns 服务器

```sh
/usr/local/etc/mosdns.yaml
```

```yml
log:
  level: info

plugins:
  - tag: cache
    type: cache
    args:
      size: 10240
      lazy_cache_ttl: 86400

  - tag: office_domain
    type: domain_set
    args:
      exps:
        - "keyword:yozosoft.com"

  - tag: forward_public
    type: forward
    args:
      concurrent: 2
      upstreams:
        - addr: udp://223.5.5.5
        - addr: udp://223.6.6.6

  - tag: forward_office
    type: forward
    args:
      concurrent: 1
      upstreams:
        - addr: tcp://192.168.9.253

  # main_sequence 里面，不能执行多条 exec 指令，所以需要这里单独定义
  - tag: office_sequence
    type: sequence
    args:
      # - exec: debug_print "111"
      - exec: $forward_office

  - tag: public_sequence
    type: sequence
    args:
      # - exec: debug_print "222"
      - exec: $forward_public

  # 主运行序列
  - tag: main_sequence
    type: sequence
    args:
      - matches:
          - qname $office_domain
        exec: $office_sequence
      - matches:
          - "!qname $office_domain"
        exec: $public_sequence

  # 启动监听服务
  - tag: udp_server
    type: udp_server
    args:
      entry: main_sequence
      listen: 127.0.0.1:53

  - tag: tcp_server
    type: tcp_server
    args:
      entry: main_sequence
      listen: 127.0.0.1:53
```

设置开机自启

```sh
sudo mosdns service install -d /usr/local/etc -c mosdns.yaml
sudo mosdns service start
sudo systemctl status mosdns
```

### 验证

```sh
dig @127.0.0.1 -p 53 google.com
nslookup -port=53 google.com 127.0.0.1
```
