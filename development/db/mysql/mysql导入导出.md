# mysql 导入导出

docker 下进入 shell

```sh
docker exec -it mysql /bin/bash
```

导出

```sh
mysqldump -u root -proot -h 127.0.0.1 -P 3306 demo_db > /var/lib/mysql/demo_db.sql
mysqldump -u root -proot -h 127.0.0.1 -P 3306 demo_db demo_table1 > /var/lib/mysql/demo_table1.sql
```

导入

```sh
mysql -u root -proot -h 127.0.0.1 -P 3306 -D demo_db < /var/lib/mysql/demo_db.sql
mysql -u root -proot -h 127.0.0.1 -P 3306 -D demo_db < /var/lib/mysql/demo_table1.sql
```
