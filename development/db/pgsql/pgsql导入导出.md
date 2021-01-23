# pgsql 导入导出

docker 下进入 shell

```sh
docker exec -it pgsql /bin/bash
```

导出

```sh
pg_dump demo_db > /var/lib/postgresql/data/demo_db.sql
pg_dump -t demo_table1 demo_db > /var/lib/postgresql/data/demo_table1.sql
```

导入

```sh
psql -d demo_db -f /var/lib/postgresql/data/my_db.sql
psql -d demo_db -f /var/lib/postgresql/data/demo_table1.sql
```

整库导出

```sh
pg_dumpall > db.out
```

整库导入

```sh
psql -f db.out
```
