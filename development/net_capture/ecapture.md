# ecapture

## 说明

linux 下抓取 https 数据，hook 实现

[地址](https://github.com/gojue/ecapture/)

## 步骤

### 监听

wireshark 格式输出

```sh
sudo ecapture tls -i eth0 -w pcapng -p 443
```

文本输出

```sh
sudo ecapture tls
```

指定 libssl 的路径

```sh
sudo ecapture tls --libssl="/usr/local/lib/libssl.so.52" --hex
```

### 请求

```sh
curl https://www.qq.com
```
