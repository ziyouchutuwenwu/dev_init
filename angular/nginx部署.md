# nginx 部署

## 如果不做配置，会有 404 错误，查资料得知，初次加载，会经过 angular 的路由，后面不会，处理方式如下

- nginx 里面

```c
server {
    listen       7777;
    server_name  localhost;

    location /backend {
        index  index.html;
        root   /web_root;
        try_files $uri $uri/ /index.html =404;
    }
}
```
