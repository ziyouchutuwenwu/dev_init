# 多app

## 说明

rebar.config

## 配置

demo1, demo2 等为自动启动的 application

```erlang
% 发布时配置
{relx, [
  {release, {demo, "0.1.0"}, [
    sasl,
    % 无依赖关系的 app
    demo1,
    demo2
  ]},

  % 其它不需要修改
]}.
```
