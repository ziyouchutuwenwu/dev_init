# swap 分区

## 说明

```sh
cat /proc/sys/vm/swappiness
```

越小说明不使用 swap
越大使用 swap
推荐设为 10

## 手动修改

```sh
sysctl vm.swappiness=10
```

/etc/sysctl.conf

```sh
vm.swappiness=10
```
