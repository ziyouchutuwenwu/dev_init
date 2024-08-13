# 构建阶段
FROM debian:12.5 as builder

ARG MIX_ENV
ENV MIX_ENV=${MIX_ENV}

WORKDIR /builder
COPY . .

ADD ./deploy/ustc.list /etc/apt/sources.list

ENV HEX_UNSAFE_HTTPS=1 HEX_MIRROR="https://hexpm.upyun.com"

# https://hexpm.upyun.com/installs/1.14.0/hex-2.0.6.ez
# cp -rf ~/.mix/elixir/1-14/rebar3 ./deploy/
RUN rm -rf /etc/apt/sources.list.d && \
  apt update && apt upgrade -y && \
  apt install build-essential openssl libssl-dev -y && \
  apt install erlang-dev elixir -y && \
  mix archive.install ./deploy/hex.ez --force && \
  mix local.rebar rebar3 ./deploy/rebar3 --force && \
  mix deps.get && \
  mix release && \
  echo "bin/spider start" > ./start.sh

# 运行阶段
FROM debian:12.5 as runner

ARG MIX_ENV
ENV MIX_ENV=${MIX_ENV}

ADD ./deploy/ustc.list /etc/apt/sources.list
RUN rm -rf /etc/apt/sources.list.d && \
  apt update && apt upgrade -y \
  && \
  ln -fs /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
  dpkg-reconfigure -f noninteractive tzdata && \
  apt install locales -y && \
  sed -i -e 's/# zh_CN/zh_CN/g' /etc/locale.gen && \
  dpkg-reconfigure -f noninteractive locales && \
  update-locale LANG=zh_CN.UTF-8

WORKDIR /runner

ENV LANG=zh_CN.UTF-8

# COPY --from=builder /builder/_build/${MIX_ENV}/rel/spider ./
COPY --from=builder /builder/_build/$MIX_ENV/rel/spider ./
COPY --from=builder /builder/run.sh .

ENTRYPOINT [ "sh", "start.sh" ]
