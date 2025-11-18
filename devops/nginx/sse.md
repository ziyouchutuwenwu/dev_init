# sse

sse 是服务端连续推送，请求是普通 http

如果是 nginx 多层代理其它的 nginx 的 sse，必须每层都设置 stream 的模式

## 例子

```conf
server {
    listen       7777;
    server_name  localhost;

    location /api/demo {
        gzip off;
        proxy_set_header Connection '';
        proxy_http_version 1.1;
        proxy_set_header Transfer-Encoding "";
        chunked_transfer_encoding off;
        proxy_buffering off;
        proxy_cache off;

        # 删除 header
        # proxy_hide_header Access-Control-Allow-Origin;
        proxy_pass http://xx.xx.xx.xx:xxxx/xxx;
    }
}
```
