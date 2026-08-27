# nginx

## 说明

主要用于区分应用场景，比如前后台

```sh
http://localhost:4200/
http://localhost:4200/xxx
```

## 步骤

### 根目录

访问路径为根目录

```sh
ng build
```

编译以后文件放到 nginx 的 web_root 下

nginx 配置

```conf
server {
    listen 7777;
    server_name localhost;

    location / {
        index index.html;
        root /web_root;
        try_files $uri $uri/ /;
    }
}
```

### 子目录

访问路径为子目录

```sh
ng build --base-href=/xxx/
```

编译以后文件放到 nginx 的 web_root 下

```conf
server {
    listen 7777;
    server_name localhost;

    location /xxx {
        alias /web_root/;
        index index.html;
        try_files $uri $uri/ /xxx/;
    }
}
```
