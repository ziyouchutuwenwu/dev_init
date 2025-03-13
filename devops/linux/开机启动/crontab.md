# crontab

## 说明

某些环境变量和在 shell 内获取的不一样

## 用法

```sh
crontab -l
crontab -e
crontab -r
```

## 调试

```sh
# 在这里重新设置环境变量
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
30 08 * * * env > /tmp/env.log
```

## 例子

命令需要全路径，否则可能会执行失败

```sh
# 重启以后执行
@reboot /opt/demo/_build/prod/rel/demo/bin/demo daemon
```

定时关机

```sh
30 17 * * * /usr/sbin/shutdown -h now
```
