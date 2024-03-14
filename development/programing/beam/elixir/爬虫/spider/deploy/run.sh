#! /bin/bash

# CURRENT_DIR=$(cd "$(dirname "$0")";pwd)

# docker里面不能成功获取deps的话
# cd $CURRENT_DIR/..; mix deps.get; cd -

BASE_DIR=/opt/spider

if [ ! $BASE_DIR ]; then
  echo "BASE_DIR is null, now exit"
  exit
fi

echo "BASE_DIR is" $BASE_DIR

docker build -t xxx-spider ../ --no-cache
docker network create --driver bridge xxx-spider-network

docker run -d --restart=always --network=xxx-spider-network --name xxx-spider-tika apache/tika:latest-full

docker run -d --restart=always --network=xxx-spider-network --name xxx-spider-splash \
-v /etc/localtime:/etc/localtime -e TZ=Asia/Shanghai \
--memory 4.5G \
scrapinghub/splash \
--maxrss 4000 --slots 20 --max-timeout 3600

docker run -d --restart=always --network=xxx-spider-network --name xxx-spider-redis \
-v $BASE_DIR"/redis_data/xxx":/data \
-v /etc/localtime:/etc/localtime -e TZ=Asia/Shanghai \
redis:6.2.1 --appendonly yes

sleep 5

docker run -d --restart=always --network=xxx-spider-network --name xxx-spider \
-v $BASE_DIR"/crawler_data/xxx":/data \
-v /etc/localtime:/etc/localtime -e TZ=Asia/Shanghai \
-e TIKA_URL=http://xxx-spider-tika:9998/tika \
-e SPLASH_URL=http://xxx-spider-splash:8050 \
-e DATA_SAVE_BASE_DIR=/data \
-e REDIS_HOST=xxx-spider-redis \
xxx-spider