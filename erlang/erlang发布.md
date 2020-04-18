# erlang 的发布

- 使用 rebar3

## rebar3 支持的格式

### release

- 可以引入多个 applicatin，并且可以独立发布

#### 引入方式

- rebar.config 修改 deps 字段，在.app.src 的 applications 字段里面添加即可

##### .app.src 的说明

```txt
{ application,test, % 名称
[{description,"Test application"}, % 描述
{vsn, "1.0.0"}, % 版本
{id, Id}, % id 同 erl -id ID
{modules, [test_app,test_sup]}, % 所有模块，systools 用来生成 script/tar 文件
{maxP, Num}, % 最大进程数
{maxT, Time}, % 运行时间 单位毫秒
{registered, [test_app]}, % 指定名称，systools 用来解决名字冲突
{included_applictions, []}, % 指定子 app，加载但不启动
{mod, {test_app,[]}}, % 启动模块，[]为参数
{env, []}, % 配置 env，可以使用 application:get_env 获取
{applications,[kernel,stdlib]}]}. % 依赖项，启动 app 前，必须有启动的 app
```

### app

- 独立的 app，可以作为 release 的库使用，

#### 导入方式

- 使用 application:start(xxx).
- 在.app.src 的 applications 字段里面添加

### lib

- 无 application 的项目，作为库引入，

#### 引用方式

- 直接 xxx:xxx().
- 在.app.src 的 applications 字段里面添加

## 注意

`lib 和 app 的区别，app 的 start 方法会被调用，lib 没有方法会被调用，只是加载`

## 打包

`rebar3 as prod tar`

## 查看已经启动的应用

```erlang
application:loaded_applications().
```

## 备注

- 进入远程 shell

```bash
erl -setcookie aaa -sname bbb@debian -remsh aaa@debian
```
