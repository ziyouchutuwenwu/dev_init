# cert

## 说明

自签名的证书

priv/cert/

```sh
# 默认只给 localhost
mix phx.gen.cert

# 指定域名
mix phx.gen.cert localhost aaa.com bbb.com
```
