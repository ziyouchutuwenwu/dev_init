#! /usr/bin/env bash

pip config set global.index-url https://mirrors.aliyun.com/pypi/simple
pip config set global.default-timeout 3600
pip config list
