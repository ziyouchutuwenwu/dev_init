# rabbitmq

## 配置

### 安装相关

#### 准备工作

目前只支持 shortname 的方式组成的集群，需要在每个主机上配置好 hosts

#### 安装

```sh
sudo apt install rabbitmq-server
```

#### 管理后台

和集群无关，只是启用管理界面, 如果不启用，在管理后台里面看到的是 Node statistics not available

```sh
sudo rabbitmq-plugins enable rabbitmq_management
```

管理后台需要 start_app 以后才能访问

```sh
http://$NODE_IP:15672
guest/guest
```

#### 节点配置

设置节点名

```sh
/etc/rabbitmq/rabbitmq-env.conf
```

修改配置以后重新启动

```sh
sudo systemctl restart rabbitmq-server
```

### 集群

#### 准备

配置 cookie，所有节点上 cookie 必须一致

```sh
/var/lib/rabbitmq/.erlang.cookie
sudo chmod 400 /var/lib/rabbitmq/.erlang.cookie
```

重启子节点

```sh
sudo systemctl restart rabbitmq-server
```

#### 加入集群

在非集群内的节点上执行，把当前节点加入集群

```sh
# 先停止，加入以后再启动
sudo rabbitmqctl stop_app
# 最后的节点为集群内任意节点
sudo rabbitmqctl join_cluster rabbit@mq1
sudo rabbitmqctl start_app
```

#### 删除节点

```sh
sudo rabbitmqctl forget_cluster_node rabbit@mq1
```

#### 查看集群信息

```sh
sudo rabbitmqctl cluster_status
```

#### 镜像策略

某节点挂掉以后，数据在其它节点上也存在，防止丢数据

```sh
sudo rabbitmqctl set_policy mirror_policy "^" '{"ha-mode":"all","ha-sync-mode":"automatic"}'
```

#### 重新加入

```sh
rm -rf /var/lib/rabbitmq/mnesia
```

然后重新加入集群

#### 辅助

erlang shell，stop_app 以后也能连接

```sh
erl -sname debug -setcookie 123456
```
