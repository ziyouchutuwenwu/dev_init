# https

## 例子

### 配置 ssl 证书

```nginx
server {
    listen 443 ssl;
    server_name  xxxxx.com;

    ssl_certificate     /usr/local/nginx/cert/xxx.pem;
    ssl_certificate_key /usr/local/nginx/cert/xxx.key;

    location /xxxx {
        proxy_pass http://xxxxxxxxxxx/;
    }
}
```

### http 转 https

80_to_443.conf

```nginx
# http 转 https
server {
  listen 80;
  server_name  xxxxx.com;
  return 301 https://$host$request_uri;
  charset utf-8;
}
```

### 阻止非法域名

block_unkown_domain.conf

```nginx
server{
  listen 80 default_server;
  server_name _;
  access_log off;
  return 404;
}

server{
  listen 443 default_server;
  server_name _;
  ssl_certificate     /usr/local/nginx/cert/xxx.pem;
  ssl_certificate_key /usr/local/nginx/cert/xxx.key;
  access_log off;
  return 404;
}

# 把重定向的 url 改成 https
proxy_redirect  http://$server_name$request_uri https://$server_name$request_uri;
```
