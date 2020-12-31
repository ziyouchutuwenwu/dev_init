package main

import (
	"check_login_demo/consts"
	"check_login_demo/middleware"
	"github.com/gogf/gf/errors/gerror"
	"github.com/gogf/gf/frame/g"
	"github.com/gogf/gf/net/ghttp"
)


func main() {
	server := g.Server()

	server.Use(middleware.LoginCheckMiddlewareHandler, middleware.ExceptionMiddlewareHandler)

	server.Group("/", func(group *ghttp.RouterGroup) {

		group.ALL("/demo1", func(r *ghttp.Request) {
			isLogin := r.GetCtxVar("isLogin")
			if isLogin.Bool(){
				r.Response.Writeln("已登录")
			}
		})

		group.ALL("/demo2", func(r *ghttp.Request) {
			isLogin := r.GetCtxVar("isLogin")
			if isLogin.Bool(){
				r.Response.Writeln("已登录")
			}else {
				err := gerror.NewCode(consts.NOT_LOGIN, "不让进去")
				panic(err)
			}
		})
	})

	server.SetPort(8199)
	server.Run()
}