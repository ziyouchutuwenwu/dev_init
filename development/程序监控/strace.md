# strace

## 说明

跟踪程序的系统调用

## 例子

跟踪子进程

```sh
strace -f ./xxx
```

看文件读写

```sh
strace -e trace=open,openat,read,write -f -p <pid>
strace -e trace=open,openat,read,write -f xxx args
```

看网络调用

```sh
strace -e trace=network ./xxx
```

显示每个系统调的时间

```sh
strace -T ./xxx
```
