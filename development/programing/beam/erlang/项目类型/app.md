# app

## 说明

application 的 start 方法会被调用

一定要注意他的返回值，否则 release 模式下启动会失败

发布需要 release

## 例子

```sh
rebar3 new app demo
```

## app.src

```erlang
{ application, demo,
  [
    % 版本号，application:which_applications().
    {vsn, "1.0.0"},

    % 作为依赖的 applications
    {applications,[
      kernel,
      stdlib
    ]},

    % 入口 application，[] 为参数
    {mod,
      {test_app,[]}
    },

    % rebar3 自动生成
    {modules, [
      aaa,
      bbb
    ]}
  ]
}.
```
