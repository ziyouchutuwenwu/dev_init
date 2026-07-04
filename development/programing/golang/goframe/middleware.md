# middleware

## 用法

- 全局 middleware
- 特定路由 middleware
- 路由组 middleware

### 优先级

- 特定路由/路由组 middleware
- 全局 middleware

### 注意

特定路由做中间件的时候，先注册路由，然后注册中间件，否则会出现问题

### 例子

```golang
package main

import (
  "github.com/gogf/gf/v2/frame/g"
  "github.com/gogf/gf/v2/net/ghttp"
  "github.com/gogf/gf/v2/os/glog"
)

func OnDemo(request *ghttp.Request) {
  request.Response.Write("ok")
}

func MiddlewareGlobal(request *ghttp.Request) {
  userId := ""
  request.SetParam("global", userId)

  if userId == "" {
    glog.Debug(nil, "global 为空")
    request.Response.WriteJsonExit(
      map[string]interface{}{
        "message": "global 为空",
        "code":    999,
      })
  }

  request.Middleware.Next()
}

func Middleware1(request *ghttp.Request) {
  userId := ""
  request.SetParam("m1", userId)

  if userId == "" {
    glog.Debug(nil, "m1 为空")
    request.Response.WriteJsonExit(
      map[string]interface{}{
        "message": "m1 为空",
        "code":    111,
      })
  }

  request.Middleware.Next()
}

func Middleware2(request *ghttp.Request) {
  userId := ""
  request.SetParam("m2", userId)

  if userId == "" {
    glog.Debug(nil, "m2 为空")
    request.Response.WriteJsonExit(
      map[string]interface{}{
        "message": "m2 为空",
        "code":    222,
      })
  }

  request.Middleware.Next()
}


func main() {
  server := g.Server()

  g.SetDebug(true)
  server.SetDumpRouterMap(false)

  server.BindHandler("/demo", OnDemo)
  server.Use(MiddlewareGlobal)
  server.BindMiddleware("/demo", Middleware1)
  server.BindMiddleware("/demo", Middleware2)

  server.SetPort(7788)
  server.Run()
}
```
