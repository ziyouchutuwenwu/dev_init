# https

## 配置

```conf
server {
    listen 443 ssl;
    server_name  .xxxxx.com;

    ssl_certificate     /usr/local/nginx/cert/xxx.pem;
    ssl_certificate_key /usr/local/nginx/cert/xxx.key;

    location /xxxx {
        proxy_pass http://xxxxxxxxxxx/;
    }
}
```
