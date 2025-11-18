# cpu

## 用法

型号

```sh
cat /proc/cpuinfo | grep name | cut -f2 -d: | uniq -c
```

物理插槽数

```sh
cat /proc/cpuinfo| grep "physical id"| sort| uniq| wc -l
```

每个物理 cpu 里面的物理核数

```sh
cat /proc/cpuinfo| grep "cpu cores"| uniq
```

逻辑个数

```sh
cat /proc/cpuinfo| grep "processor"| wc -l
```
