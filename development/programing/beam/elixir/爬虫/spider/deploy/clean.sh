#! /bin/bash

docker kill xxx-spider
docker kill xxx-spider-redis
docker kill xxx-spider-splash
docker kill xxx-spider-tika

docker rm -v xxx-spider
docker rm -v xxx-spider-redis
docker rm -v xxx-spider-splash
docker rm -v xxx-spider-tika

docker network rm xxx-spider-network
docker rmi xxx-spider:latest --force