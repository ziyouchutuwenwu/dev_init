# erlang 交叉编译

```sh
sudo apt install qemu-user-static
```

`没有这个，arm 架构的在电脑上启动不了`

## 使用 debootstrap

```sh
sudo apt install debootstrap
sudo debootstrap --arch=armel buster ./buster https://mirrors.tuna.tsinghua.edu.cn/debian/
sudo chroot ./buster /bin/bash
```

## 使用 docker

先启动容器

```sh
docker run -it --name arm-erlang --network host --rm -v ~/projects/erlang/:/usr/src arm32v7/erlang
```

然后

```sh
cd /usr/src/xxx
./rebar3 as prod tar
```
