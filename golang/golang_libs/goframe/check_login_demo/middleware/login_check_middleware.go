package middleware

import (
    "github.com/gogf/gf/net/ghttp"
)

func LoginCheckMiddlewareHandler(r *ghttp.Request) {

    if (r.RequestURI == "/demo1"){
        r.SetCtxVar("isLogin", true)
    }

    r.Middleware.Next()
}