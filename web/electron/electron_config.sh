#! /usr/bin/env /bin/bash

npm config set registry "https://registry.npm.taobao.org"
npm config set electron_mirror "https://npm.taobao.org/mirrors/electron/"
npm config set chromedriver_cdnurl "https://npm.taobao.org/mirrors/chromedriver"
npm config set sass_binary_site "https://npm.taobao.org/mirrors/node-sass/"

echo "electron7以后，淘宝镜像比官方在url里面少了一个v，需要配置"
# 处理官方和淘宝镜像站的区别
npm config set electron_custom_dir 8.0.1
