# ports 用法

## 执行命令

需要到 /usr/ports 下面

或者

```sh
make -C /usr/ports xxx
```

## 更新索引

更新 ports 的索引

```sh
make -C /usr/ports fetchindex
```

## 默认 install 路径

```sh
/usr/local/bin
```

## 日常用法

- 搜索源码

```sh
cd /usr/ports
make search name=curl
```

- 安装

```sh
cd /usr/ports/directory
make install clean
```

- 仅仅下载源码包，而不安装

```sh
cd /usr/ports/directory
make fetch
```

- 预先知道需要那些包，才能安装这个软件：

```sh
cd /usr/ports/directory
make fetch-list
make fetch-recursive
```

- 把软件装到指定的目录：

```sh
cd /usr/ports/directory
make PREFIX=/usr install
```

## 清理

重新安装一遍通过 port 安装的软件以后，清理不需要的东西

```sh
freebsd-update install
```
