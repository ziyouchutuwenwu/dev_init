# phoenix 项目

[参考地址](https://hexdocs.pm/phoenix/deployment.html)

## 例子

```sh
export MIX_ENV=prod

mix deps.get
mix assets.deploy
# mix ecto.migrate
mix release

export SECRET_KEY_BASE=$(mix phx.gen.secret | tail -n 1)
export PHX_SERVER=true
export PHX_HOST="aaa.com"
export PORT=9876;

_build/prod/rel/web_demo/bin/web_demo start
```
