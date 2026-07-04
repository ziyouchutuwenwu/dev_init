# observer_cli

## 说明

用于分析线上 bug

## 用法

rebar.config

```erlang
{deps, [observer_cli]}
```

启动

```erlang
% 本地节点
observer_cli:start().

% 远程节点
observer_cli:start('aaa@127.0.0.1', '123456').
```

按对应字母以后回车，切换面板
