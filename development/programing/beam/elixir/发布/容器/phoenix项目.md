# phoenix 项目

## 说明

可以用两阶段方式，也可以用普通方式

## 例子

Dockerfile

```dockerfile
FROM hexpm/elixir:1.18.4-erlang-27.0.1-debian-bookworm-20250428

WORKDIR /app

RUN mix local.hex --force && \
    mix local.rebar --force

COPY . .

ENV MIX_ENV=prod

RUN mix deps.get && \
    mix compile

EXPOSE 4000

CMD SECRET_KEY_BASE=$(mix phx.gen.secret) mix phx.server
```

build

```sh
docker build . \
    --build-arg "HTTP_PROXY=http://10.0.2.1:8118" \
    --build-arg "HTTPS_PROXY=http://10.0.2.1:8118" \
    --build-arg "NO_PROXY=localhost,127.0.0.1,10.0.2.1" \
    -t web-demo
```

运行

```sh
docker run --name demo --rm -d web-demo
# docker run --name demo -d --restart=always demo
```
