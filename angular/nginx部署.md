# nginx部署

## 如果不做配置，会有404错误，查资料得知，初次加载，会经过angular的路由，后面不会，处理方式如下

- nginx里面

```c
index index.html;

location / {
    try_files $uri $uri/ /index.html;
}
```
