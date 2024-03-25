# 构建和运行的 glibc 版本最好一致，运行期需要 libcrypto
FROM elixir:1.16-slim as building

WORKDIR /build
COPY . .

ENV HEX_UNSAFE_http=1 HEX_MIRROR="http://hexpm.upyun.com"

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
FROM debian:bookworm-20240311-slim as app

# 装 libcrypto
RUN echo 'deb http://mirrors.ustc.edu.cn/debian/ bookworm main contrib non-free non-free-firmware \
  deb-src http://mirrors.ustc.edu.cn/debian/ bookworm main contrib non-free non-free-firmware \
\
  deb http://mirrors.ustc.edu.cn/debian/ bookworm-updates main contrib non-free non-free-firmware  \
  deb-src http://mirrors.ustc.edu.cn/debian/ bookworm-updates main contrib non-free non-free-firmware  \
\
  deb http://mirrors.ustc.edu.cn/debian/ bookworm-backports main contrib non-free  \
  deb-src http://mirrors.ustc.edu.cn/debian/ bookworm-backports main contrib non-free  \
\
  deb http://mirrors.ustc.edu.cn/debian-security/ bookworm-security main contrib non-free non-free-firmware  \
  deb-src http://mirrors.ustc.edu.cn/debian-security/ bookworm-security main contrib non-free non-free-firmware' > /etc/apt/sources.list

RUN rm -rf /etc/apt/sources.list.d/debian.sources && \
  apt update && \
  apt install libssl3 -y

# 用于网络调试
# RUN sed -i 's/deb.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list
# RUN apt update; apt upgrade -y; apt install -y netcat curl iputils-ping net-tools

WORKDIR /app
COPY --from=building /build/_build/prod/rel/spider ./

ENTRYPOINT [ "bin/spider", "start" ]