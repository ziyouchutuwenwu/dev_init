# phoenix 项目

[参考地址](https://hexdocs.pm/phoenix/deployment.html)

## 步骤

### 原生发布

```sh
mix deps.get --only prod
MIX_ENV=prod mix compile

MIX_ENV=prod mix assets.deploy
# MIX_ENV=prod mix ecto.migrate
MIX_ENV=prod mix release
export SECRET_KEY_BASE=`mix phx.gen.secret` PHX_SERVER=true PHX_HOST="aaa.com" PORT=9876;
_build/prod/rel/web_demo/bin/web_demo start
```

### docker 发布

```dockerfile
# 构建阶段
FROM debian:12.5 as builder

WORKDIR /build
COPY . .

ADD ./deploy/ustc.list /etc/apt/sources.list

ENV HEX_UNSAFE_HTTPS=1 HEX_MIRROR="https://hexpm.upyun.com"

# cp -rf ~/.mix/elixir/1-14/rebar3 ./deploy/
RUN rm -rf /etc/apt/sources.list.d && \
  apt update && apt upgrade -y && \
  apt install build-essential openssl libssl-dev -y && \
  apt install erlang-dev elixir -y && \
  mix archive.install ./deploy/hex.ez --force && \
  mix local.rebar rebar3 ./deploy/rebar3 --force && \
  mix deps.get --only prod && \
  MIX_ENV=prod mix release && \
  # 先运行一次, 不然可能会有某些没有编译的库导致环境变量报错
  MIX_ENV=prod mix phx.gen.secret && \
  echo "export SECRET_KEY_BASE=`MIX_ENV=prod mix phx.gen.secret`" > ./run.sh && \
  echo "bin/ai_data start" >> ./run.sh

# 运行阶段
FROM debian:12.5 as runner

ADD ./deploy/ustc.list /etc/apt/sources.list
RUN rm -rf /etc/apt/sources.list.d && \
  apt update && apt upgrade -y && \
  apt install build-essential openssl libssl-dev -y && \
  apt install zip unzip unrar -y

WORKDIR /app

COPY --from=builder /build/_build/prod/rel/ai_data ./
COPY --from=builder /build/run.sh .

ENTRYPOINT [ "sh", "run.sh" ]
```
