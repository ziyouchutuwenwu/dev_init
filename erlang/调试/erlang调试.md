# erlang 的调试配置

## 插件

官方插件无法调试，推荐使用 [这个版本](https://github.com/yidayoung/intellij-erlang)，zip 包直接可以离线安装

## 简单模块调试

```sh
用 idea 自带的项目创建模块
直接模块的方法上面下断点，然后 debug 即可
```

### 注意

```sh
如果提示模块名错误，F4 打开项目选项，把 src 目录作为 source
如果提示 `Invalid beam file or no abstract code`，可以在调试配置里面，在 erl 的命令行里面添加编译以后的 beam 路径
```

```sh
-pa _build/default/lib/你的项目名字/ebin
```

## opt 项目调试

```sh
创建 rebar3 的项目 `rebar3 new app test_app`
创建一个这样的 erl，然后用上面一样的办法做模块级别的 debug，编译可以自己创建一个 rebar3 compile 的 task
复制 `_only_for_debug_` 目录到项目

调试
  选项里面的模块和函数为`debug debug`
  参数为 `AppName`, 注意：`AppName` 不含 `.app` 后缀
  例如: xxx.app.src, 则 AppName 为 xxx
```

## 远程调试

[参考链接](https://blog.csdn.net/eeeggghit/article/details/106021723)

### 创建一个目标 shell

```sh
erl -name aaa@127.0.0.1 -setcookie 111
```

或者在 idea 节点里面，创建一个这样的 erlang console

### 创建一个调试用的 remote 节点

一些信息如下配置

```sh
remote node name: aaa@127.0.0.1
cookie: 111

不勾选use short names
host： 127.0.0.1
```

interpret scope，设置为全工程，否则会跑飞

### 调试

代码下断点，然后在 idea 下面的 erlang 的 shell 里面的输入调用的模块，会中断，完美
