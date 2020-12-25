# erlang 的调试配置

## 插件

官方插件无法调试，推荐使用 [这个版本](https://github.com/yidayoung/intellij-erlang)

### 修改插件包的版本

```sh
用解压软件打开压缩包，不要解压
找到 intellij-erlang-0.11.2000.zip\intellij-erlang\lib\intellij-erlang-0.11.2000.jar\META-INF
修改 plugins.xml 中的 until-build 字段
```

### 自己构建

```sh
git clone https://github.com/yidayoung/intellij-erlang
修改build.gradle的 patchPluginXml 字段
./gradlew buildPlugin
```

生成目录在 `build/distributions/`

## 简单模块调试

```sh
用 idea 自带的项目创建模块
直接模块的方法上面下断点，然后 debug 即可
```

### 注意

如果提示 `Invalid beam file or no abstract code`，可以在调试配置里面，使用 -pa 添加路径

路径不能使用通配符，如果还是提示无法解析，使用全路径

```sh
-pa _build/default/lib/xxxx/ebin/
```

## opt 项目调试

```sh
创建 rebar3 的项目 `rebar3 new app test_app`
调试选择erlang application，做 Module 级别的 debug，编译可以自己创建一个 rebar3 compile 的 task
复制 `_only_for_debug_` 目录到项目

调试
  选项里面的模块和函数为`debug debug`
  参数为 `AppName`, 注意：`AppName` 不含 `.app` 后缀
  例如: xxx.app.src, 则 AppName 为 xxx
```

## 远程调试（推荐）

[参考链接](https://blog.csdn.net/eeeggghit/article/details/106021723)

### 创建一个目标 shell

```sh
erl -name console@127.0.0.1 -setcookie debug
```

或者

```sh
erl -sname console -setcookie debug
```

或者在 idea 节点里面，创建一个这样的 erlang console

### 创建一个调试用的 remote 节点

一些信息如下配置

使用 short name 模式，注意 `remote node name`后面的本机 host 必须要填上

```sh
remote node name: console@debian
cookie: debug

不勾选 use short names
host： 127.0.0.1
```

使用 long name 模式

```sh
remote node name: console@127.0.0.1
cookie: debug

不勾选 use short names
host： 127.0.0.1
```

然后 -pa 添加 beam 的路径

interpret scope，设置为全工程，否则会跑飞

### 调试

代码下断点，然后在 idea 下面的 erlang 的 shell 里面的输入调用的模块，会中断，完美
