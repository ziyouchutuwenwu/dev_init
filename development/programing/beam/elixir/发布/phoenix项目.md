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

ARG MIX_ENV
ENV MIX_ENV=${MIX_ENV}

WORKDIR /build
COPY . .

ADD ./deploy/ustc.list /etc/apt/sources.list

ENV HEX_UNSAFE_HTTPS=1 HEX_MIRROR="https://hexpm.upyun.com"

# https://repo.hex.pm/installs/1.14.0/hex-2.1.1.ez
# cp -rf ~/.mix/elixir/1-14/rebar3 ./deploy/
RUN rm -rf /etc/apt/sources.list.d && \
  apt update && apt upgrade -y && \
  apt install build-essential openssl libssl-dev -y && \
  apt install erlang-dev elixir -y && \
  mix archive.install ./deploy/hex.ez --force && \
  mix local.rebar rebar3 ./deploy/rebar3 --force && \
  mix deps.get && \
  mix release && \
  # 先运行一次, 不然可能会有某些没有编译的库导致环境变量报错
  mix phx.gen.secret && \
  echo "export SECRET_KEY_BASE=`mix phx.gen.secret`" > ./run.sh && \
  echo "bin/web_demo start" >> ./run.sh

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
  update-locale LANG=zh_CN.UTF-8 \
  && \
  apt install build-essential openssl libssl-dev -y && \
  apt install zip unzip unrar -y

WORKDIR /app

ENV LANG=zh_CN.UTF-8

COPY --from=builder /build/_build/$MIX_ENV/rel/web_demo ./
COPY --from=builder /build/run.sh .

ENTRYPOINT [ "sh", "run.sh" ]
```

run.sh

```sh
#! /bin/bash

if [ "$#" -ne 7 ]; then
  echo "$0 mix_env db_host db_port db_user db_pwd db_name auto_review_url"
  exit
fi

mix_env=$1
db_host=$2
db_port=$3
db_user=$4
db_pwd=$5
db_name=$6
auto_review_url=$7

docker build --build-arg MIX_ENV=$mix_env -t web-demo ../ --no-cache

docker run -d --restart=always --name web-demo \
  -p 4000:4000 \
  -e DATABASE_URL="ecto://$db_user:$db_pwd@$db_host:$db_port/$db_name" \
  -e PHX_SERVER=true \
  -e AUTO_REVIEW_URL=$auto_review_url \
  web-demo
```

clear.sh

```sh
#! /bin/bash

docker kill web-demo
docker rm -v web-demo

docker rmi web-demo --force
```
