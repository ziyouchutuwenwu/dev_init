package middleware

import (
    "check_login_demo/consts"
    "github.com/gogf/gf/errors/gerror"
    "github.com/gogf/gf/net/ghttp"
)

func ExceptionMiddlewareHandler(r *ghttp.Request) {
    r.Middleware.Next()

    if err := r.GetError(); err != nil {
        if ( gerror.Code(err) == consts.NOT_LOGIN ){

            r.Response.ClearBuffer()
            r.Response.Writeln("没有经过授权，不让进")
            //r.Response.RedirectTo("https://www.baidu.com")
        }
    }
}