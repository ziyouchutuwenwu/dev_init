# epmd_less

## 说明

容器情况下，一个容器跑一个节点，多个容器固定使用某个端口通信

## 配置

vm.args.src

```sh
-start_epmd false
# -erl_epmd_port 6789
-erl_epmd_port ${DIST_PORT}
```

remote shell

```sh
# 自动添加
-dist_listen false

# vm.args 里面提取的字段
name/sname
setcookie
start_epmd
proto_dist
inet_dist_use_interface
```
