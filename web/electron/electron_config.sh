#! /usr/bin/env /bin/bash

npm config set registry "https://registry.npm.taobao.org"
npm config set electron_mirror "https://npm.taobao.org/mirrors/electron/"

# npm config set disturl https://npm.taobao.org/dist

echo "electron7以后，淘宝镜像比官方在url里面少了一个v，需要配置这个"
# 处理官方和淘宝镜像站的区别
npm config set electron_custom_dir 8.0.1