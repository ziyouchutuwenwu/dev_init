# linuxcnc

## 实时性测试

```sh
sudo apt install stress rt-tests
```

cpu 满载

```sh
stress -v -c 8 -i 10 -d 8
```

看延迟数据

```sh
sudo cyclictest -p 90 - m -c 0 -i 200 -n -h 100 -q -l 100000
```

## 测试结果

```sh
debian10 版本
不超过50微妙

debian7 版本
不超过10微妙
```

## 启动换命令行

debian 10 版

```sh
sudo systemctl set-default multi-user.target
```

如果觉得启动的时候 grub 界面也不要显示，可以

```sh
vi /etc/default/grub
修改 GRUB_TIMEOUT
```
