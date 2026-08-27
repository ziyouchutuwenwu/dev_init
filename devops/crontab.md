# crontab

## 说明

freebsd 和 linux 都支持

/etc/profile 默认不会加载，需要手动激活

## 用法

```sh
crontab -l
crontab -e
crontab -r
```

## 例子

```sh
# 重启以后执行
@reboot . /etc/profile; /opt/demo/_build/prod/rel/demo/bin/demo daemon
```

定时关机

```sh
30 17 * * * /usr/sbin/shutdown -h now
```
