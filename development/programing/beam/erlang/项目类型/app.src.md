# app.src

## 说明

.app.src

```erlang
% 当前应用名称
{ application,test,
  [
    % 版本号，application:which_applications(). 的时候看到
    {vsn, "1.0.0"},

    % 启动 app 前，需要先启动的 app
    {applications,[
      kernel,
      stdlib
    ]},

    % 注册 application
    % app 和 release 都会自动创建，[]为参数
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
