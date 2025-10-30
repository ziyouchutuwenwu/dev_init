# app

## 说明

app 里面，application 的 start 方法会被调用

一定要注意他的返回值，否则 release 模式下启动会失败

## app.src

```erlang
% 当前应用名称
{ application,test,
  [
    % 版本号，application:which_applications(). 的时候看到
    {vsn, "1.0.0"},

    % 启动当前 application 前，需要先启动的 app
    % 这里放业务无关的，用于依赖的 applications
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
