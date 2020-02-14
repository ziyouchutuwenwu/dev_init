# nginx部署

## 如果不做配置，会有404错误，查资料得知，初次加载，会经过angular的路由，后面不会，处理方式如下

- nginx里面

```c
server {
    listen       7777;
    server_name  localhost;

    location / {
        index  index.html;
        root   /web_root;
        try_files $uri $uri/ /index.html =404;
    }
}
```

- 不支持相对路径启动，详情见[这里](https://github.com/angular/angular/issues/30835)
