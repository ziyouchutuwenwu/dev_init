# wireshark

https 抓包

## 步骤

### 设置环境变量

```sh
export SSLKEYLOGFILE=/tmp/sslkey.log
```

打开 chrome 访问 https 网站，看 sslkey.log 有没有内容

### 参数配置

指定 key 文件路径

```sh
编辑 -> 首选项 -> protocols -> tls -> (Pre)-Master-Secret log filename
```
