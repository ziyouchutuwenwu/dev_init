# mysql 导入导出

docker 下进入 shell

```sh
docker exec -it mysql /bin/bash
```

导出

```sh
mysqldump -uroot -proot my_db > /var/lib/mysql/my_db.sql
mysqldump -uroot -proot my_db demo_table1 > /var/lib/mysql/demo_table1.sql
```

导入

```sh
mysql -uroot -proot -h127.0.0.1 -P 3306 -D my_db < /var/lib/mysql/my_db.sql
mysql -uroot -proot -h127.0.0.1 -P 3306 -D my_db < /var/lib/mysql/demo_table1.sql
```
