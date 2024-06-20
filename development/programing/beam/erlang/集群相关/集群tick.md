# 集群 tick

集群的节点通信的心跳时间

## 说明

默认为 60s

```erlang
net_kernel:get_net_ticktime().
```

修改

```erlang
net_kernel:set_net_ticktime
```

## 注意事项

当一个节点掉线以后，不应该立刻重启

为了让集群内所有节点都认为该节点死掉，一般需要等待该节点心跳时间 \* 1.5

否则远程 rpc 会锁死
