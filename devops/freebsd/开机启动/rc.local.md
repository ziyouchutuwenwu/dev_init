# rc.local

## 用法

位置

```sh
chmod a+x /etc/rc.local
```

内容

```sh
#!/bin/sh -e

# nohup xxx > /dev/null 2>&1 &
# screen -dm xxx

/opt/demo/_build/prod/rel/demo/bin/demo daemon

exit 0
```
