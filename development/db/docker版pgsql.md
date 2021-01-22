# docker 版 pgsql

进入 docker 的 shell 以后，用法和传统的一样

```sh
docker exec -it pgsql /bin/bash
```

pgcli 用法

```sh
pgcli -h 127.0.0.1 -p 6543 -u my_user -d my_db
pgcli postgres://my_user:123456@127.0.0.1:6543/my_db

pgcli postgres://my_user:password@db_host:port/my_db
```
