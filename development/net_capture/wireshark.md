# wireshark

https 抓包

## 步骤

### 环境变量

```sh
export SSLKEYLOGFILE=/tmp/ssl_key.log
```

打开 chrome 访问 https 网站，看 ssl_key.log 有没有内容

### 参数配置

指定 key 文件路径

```sh
编辑 -> 首选项 -> protocols -> tls -> (Pre)-Master-Secret log filename
```

```sh
分析 -> 启用的协议, 全选
```

wireshark 的过滤器输入

```sh
http || http2
```

## 注意

如果抓不到数据，在命令行启动 chrome
