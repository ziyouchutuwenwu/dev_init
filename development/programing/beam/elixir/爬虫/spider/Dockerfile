# 构建阶段
# libc 2.31
FROM elixir:1.14.2-slim as building

WORKDIR /build
COPY . .

ENV HEX_UNSAFE_HTTPS=1 HEX_MIRROR="http://hexpm.upyun.com"

RUN mix local.hex --force && \
  mix local.rebar --force && \
  mix deps.get --only prod && \
  MIX_ENV=prod mix release
# 如果 mix local.hex 和 mix local.rebar 都下载失败
# 手动下载 hex.ez
# cp -rf ~/.mix/elixir/1-14/rebar3 ./deploy/
# RUN mix archive.install ./deploy/hex.ez --force && \
#   mix local.rebar rebar3 ./deploy/rebar3 --force && \
#   MIX_ENV=prod mix release

# 运行阶段
FROM debian:stable-20221004-slim as app

# 用于网络调试
# RUN sed -i 's/deb.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list
# RUN apt update; apt upgrade -y; apt install -y netcat curl iputils-ping net-tools

WORKDIR /app
COPY --from=building /build/_build/prod/rel/spider ./

ENTRYPOINT [ "bin/spider", "start" ]