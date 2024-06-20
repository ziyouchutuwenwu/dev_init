# cmd 和 entrypoit

[参考连接](https://www.cnblogs.com/sparkdev/p/8461576.html)

## shell 模式和 exec 模式

### exec 模式

注意需要使用双引号

```sh
["executable","param1","param2"]
```

此模式下不能获取环境变量，除非在 exec 模式下启动 shell，比如

```sh
CMD ["sh", "-c", "echo $HOME"]
```

### shell 模式

```sh
command param1 param2
```

此模式能直接获取环境变量

```sh
CMD echo $HOME
```

## 需要覆盖默认命令启动

以 CMD 为默认执行命令启动

```sh
CMD [ "top" ]
```

或者

```sh
CMD top
```

## 需要添加到启动参数列表中

exec 模式时，docker run 的命令行参数会作为参数添加到 ENTRYPOINT 指定命令的参数列表中，比如

```sh
ENTRYPOINT [ "top", "-b" ]
```

## 指定默认的可选参数, 可覆盖

docker run 可覆盖, CMD 后面为默认可选参数，docker run 的命令覆盖 CMD 之后的指令

```sh
ENTRYPOINT [ "top", "-b" ]
CMD [ "-c" ]
```

## 完全忽略命令行参数

ENTRYPOINT 为 shell 模式, 会忽略 docker run 的命令行参数

```sh
ENTRYPOINT echo $HOME
```

## 覆盖默认的 ENTRYPOINT 指令

docker run 使用 --entrypoint 参数
