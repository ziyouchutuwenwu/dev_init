# release

## 说明

支持多 app，并且可以独立发布

## 例子

```sh
rebar3 new release xxx
cd xxx/apps

rebar3 new app demo1
rebar3 new app demo2
```

## 注意

子应用的自启动，在 rebar.config 里面注册

```erlang
{relx, [
  {release, {demo, "0.1.0"}, [
    % 业务型，自启动应用
    % 具体见发布环节
    sasl,
    demo1,
    demo2
  ]},

  {mode, dev}
]}.
```
