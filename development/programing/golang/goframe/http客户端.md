# http 客户端

http 调用微服务，需要注意后端超时时间

## 代码

```go
func GetHttpClientTimeOutDuration() time.Duration {
  duration := genv.Get("HTTP_CLIENT_TIMEOUT_DURATION")
  return time.Duration(gconv.Int64(duration))
}

httpClient.SetTimeout(consts.GetHttpClientTimeOutDuration() * time.Second)
```
