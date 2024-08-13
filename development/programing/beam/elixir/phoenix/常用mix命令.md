# 常用 mix 命令

## 列表如下

### 生成随机数

默认长度 64 位

```sh
mix phx.gen.secret
```

### 表 model 和 curd

创建表 model，migration, curd 代码

```sh
mix phx.gen.context
```

例如

创建 user 为表 model, migration, curd 代码

```sh
mix phx.gen.context Accounts User users name:string age:integer
```

### 创建 html

创建 user 为模型的表 model, migration, controller, view，curd 代码

```sh
mix phx.gen.html Accounts User users name:string age:integer
```

### 创建 json

创建表 model, migration, controller, view，curd 代码

```sh
mix phx.gen.json
```

例如

创建 user 为模型的表 model, migration, controller, view，curd 代码

```sh
mix phx.gen.json Accounts User users name:string age:integer
```

### 生成 auth

用于生成用户注册登陆的一系列傻瓜式代码

- Fronted.Accounts 对应 lib/xxx_demo/下 auth 相关功能模块的目录
- User 为 model
- users 为表名，--table 可以指定另外的表名
- --web 为一些模板所在的控制器路径
- --binary-id uuid 作为 id

```sh
mix phx.gen.auth Fronted.Accounts User users --web MyWeb --table accounts_users --binary-id
```

指定 uuid 还可以这样

```elixir
config :web_demo, :generators,
  binary_id: true
```

### 生成 notifier

用于发邮件

- Accounts 对应命名空间
- User 为 模块名
- f1 对应方法名为 deliver_f1

```sh
mix phx.gen.notifier Accounts User f1 f2 f3
```

在 umbrella 项目里，创建指定 app 的 notifier

```sh
mix phx.gen.notifier Accounts User welcome_user --context-app app1
```

### 生成 live

通过 websocket 通信，页面提速

```sh
mix phx.gen.live Accounts User users name:string age:integer --web MyWeb
```
