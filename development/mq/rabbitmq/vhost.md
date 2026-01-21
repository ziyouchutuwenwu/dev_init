# vhost

## 说明

vhost 用于为不同的应用或服务提供独立的命名空间和资源隔离

## 例子

创建 vhost

```sh
rabbitmqctl add_vhost vhost1
```

删除 vhost

```sh
rabbitmqctl delete_vhost vhost1
```

查看列表

```sh
rabbitmqctl list_vhosts
```

设置用户在某个 vhost 下的权限

```sh
# rabbitmqctl set_permissions -p vhost_name username configure write read
rabbitmqctl set_permissions -p vhost1 user1 ".*" ".*" ".*"
```

查看用户在某个 vhost 下的权限

```sh
rabbitmqctl list_user_permissions user1
```
