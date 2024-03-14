# Spider

## 调试

准备工作

```sh
docker run --rm -d --name tika-dev -p 9998:9998 apache/tika:latest-full
docker run --rm -d --name splash-dev -p 8050:8050 --memory 4.5G scrapinghub/splash --maxrss 4000 --slots 20 --max-timeout 3600
docker run --rm -d --name redis-dev -p 6379:6379 -e TZ=Asia/Shanghai redis:6.2.1

docker exec -it redis-dev bash -c 'redis-cli flushdb'
# docker exec -it redis-dev bash -c 'redis-cli keys "*"'

docker kill tika-dev splash-dev redis-dev
```

```sh
MIX_ENV=dev iex -S mix
```

## 生产

```sh
docker logs -f xxx-spider
docker exec -it xxx-spider bin/spider remote
docker exec -it xxx-spider bash
```
