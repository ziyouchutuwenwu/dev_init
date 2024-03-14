# crontab

## 说明

适用 linux, freebsd

crontab 可以根据用户区分当前目录

## 例子

```sh
crontab -e
@reboot /opt/demo/_build/prod/rel/demo/bin/demo daemon
```
