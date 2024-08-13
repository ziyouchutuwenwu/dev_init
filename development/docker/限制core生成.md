# 限制 core 生成

如果容器内服务崩溃重启，会产生 core 文件，如果不需要，可用修改配置

## 步骤

### 修改配置

```sh
vim /usr/lib/systemd/system/docker.service
```

类似 `--default-ulimit` 是关键

```sh
ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock --default-ulimit core=0:0
```

### 重启

```sh
systemctl daemon-reload
systemctl restart docker
```
