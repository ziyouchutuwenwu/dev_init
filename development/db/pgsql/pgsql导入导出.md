# pgsql 导入导出

docker 下进入 shell

```sh
docker exec -it pgsql /bin/bash
```

导出

```sh
pg_dump my_db > /var/lib/postgresql/data/my_db.sql
pg_dump -t demo_table1 my_db > /var/lib/postgresql/data/demo_table1.sql
```

导入

```sh
psql -d my_db -f /var/lib/postgresql/data/my_db.sql
psql -d my_db -f /var/lib/postgresql/data/demo_table1.sql
```
