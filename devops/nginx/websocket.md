# websocket

## 例子

```conf
server {
    listen       7777;
    server_name  localhost;

    location /aaa {
        proxy_pass http://xx.xx.xx.xx:xxxx/xxx;
        proxy_read_timeout 300s;
        proxy_send_timeout 300s;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

        proxy_http_version 1.1;
        proxy_set_header Upgrade "websocket";
        proxy_set_header Connection "Upgrade";
    }
}
```
