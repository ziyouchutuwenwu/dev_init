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
% 应用名称, 和 application:which_applications(). 一致，代码里面，是 demo_app
{ application, demo,
  [
    % 版本号，application:which_applications().
    {vsn, "1.0.0"},

    % 业务无关的，需要先启动的 app，一般是作为依赖的 applications
    % 业务相关的，放在 rebar.config 里面，见 release 文档
    {applications,[
      kernel,
      stdlib
    ]},

    % 入口 application，[] 为参数
    % 依赖的 applications 启动以后，也会被启动
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
