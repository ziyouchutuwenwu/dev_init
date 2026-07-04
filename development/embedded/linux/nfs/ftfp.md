# tftp

## 配置

### 服务端

host 模式

```sh
docker run --rm -d -it --name=tftpd --net=host -v ~/projects/docker/tftp:/srv/tftp hkarhani/tftpd
```

端口映射模式

```sh
docker run --rm -d -it --name=tftpd -p 69:69/udp -v ~/projects/docker/tftp:/srv/tftp hkarhani/tftpd
```

### 测试

```sh
tftp 10.0.2.1
get xxx
```
