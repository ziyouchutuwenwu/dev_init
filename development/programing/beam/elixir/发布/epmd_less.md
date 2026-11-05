# epmd_less

## 说明

容器情况下，一个容器跑一个节点，多个容器固定使用某个端口通信

## 配置

vm.args.eex

```sh
# 本地启动的服务，不启动 epmd，直接使用 6789
-start_epmd false -erl_epmd_port 6789
```

remote.vm.args.eex

```sh
# remote shell 不启动 epmd, 也不启动指定的 6789 端口
-start_epmd false -erl_epmd_port 6789 -dist_listen false
```
