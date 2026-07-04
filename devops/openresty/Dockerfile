FROM openresty/openresty:alpine

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories
# opm 依赖
RUN apk add --no-cache curl perl fd ripgrep

# 使用 opm 安装 lua-resty-http
RUN /usr/local/openresty/bin/opm get xiangnanscu/lua-resty-ipmatcher

COPY nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
# /usr/local/openresty/nginx/lua/

WORKDIR /usr/local/openresty/nginx

# 暴露端口
EXPOSE 80

# 启动命令
CMD ["/usr/local/openresty/bin/openresty", "-g", "daemon off;"]
