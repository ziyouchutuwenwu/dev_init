# erlang 的调试配置

## 同步模块调试

- 用 idea 自带的项目创建模块
- 直接模块的方法上面下断点，然后 debug 即可

### 注意

- 如果提示模块名错误，F4 打开项目选项，把 src 目录作为 source
- 如果提示 `Invalid beam file or no abstract code`，可以在调试配置里面，在 erl 的命令行里面添加编译以后的 beam 路径

```bash
-pa _build/default/lib/你的项目名字/ebin
```

- 调试之前，自动构建，则可以在 debug 的时候，选择在调试选项里面选择 before launch 添加一个 task

## 异步调试，比较典型的为 opt 项目的断点调试

- [参考链接]([https://shayu.ltd:1688/articles/2019/10/22/1571726190169.html), 链接里面缺少修改`supervisor`

- 创建 rebar3 的项目 `rebar3 new app test_app`
- 创建一个这样的 erl，然后用上面一样的办法做模块级别的 debug，编译可以自己创建一个 rebar3 compile 的 task
- 复制 `_only_for_debug_` 目录到项目
- 调试
  - 选项里面的模块和函数为`debug debug`
  - 参数为 `AppName`, 注意：`AppName` 不含 `.app` 后缀，例如: xxx.app.src, 则 AppName 为 xxx
