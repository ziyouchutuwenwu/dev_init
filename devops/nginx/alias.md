# alias

## 说明

alias 后面的路径(一定要有斜杠) + location 的文件名(不带 location 路径)

例如

| uri          | 物理路径                  |
| ------------ | ------------------------- |
| /aaa/bb.html | /web_root/backend/bb.html |

## 配置

```conf
location /aaa/ {
    alias /web_root/backend/;
    index index.html index.htm;
    try_files $uri $uri/ /aaa/index.html;
}
```
