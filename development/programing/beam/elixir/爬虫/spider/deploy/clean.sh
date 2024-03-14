#! /bin/bash

docker kill xxx-spider
docker kill xxx-spider-redis
docker kill xxx-spider-splash
docker kill xxx-spider-tika

docker rm xxx-spider
docker rm xxx-spider-redis
docker rm xxx-spider-splash
docker rm xxx-spider-tika

docker network rm xxx-spider-network
docker rmi xxx-spider:latest --force