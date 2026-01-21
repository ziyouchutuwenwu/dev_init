# release

## 说明

支持多 app

独立发布，运行不需要机器预装 erlang

## 例子

```sh
rebar3 new release xxx
cd xxx/apps

rebar3 new app demo1
rebar3 new app demo2
```

## 注意

rebar.config

```erlang
{relx, [
  {release, {demo, "0.1.0"}, [
    % 业务无关的，需要先启动的 app，放在 app.src 里面
    % 这里放业务相关的子 app，自启动应用，具体见发布环节
    sasl,
    demo1,
    demo2
  ]},

  {mode, dev}
]}.
```
