# pgsql 远程访问

开启远程权限

```sh
cd /etc/postgresql/版本号/main
```

vim postgresql.conf

```sh
listen_addresses ='*'
```

vim pg_hba.conf, 添加一行

```sh
host all all 0.0.0.0/0 md5
```
