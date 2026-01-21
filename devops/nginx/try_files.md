# try_files

## 说明

参数拿到的路径是不带 location 的

## 例子

```conf
location /aaa/ {
    alias /web_root/backend/;
    index index.html index.htm;
    try_files $uri $uri/ /aaa/index.html;
}
```
