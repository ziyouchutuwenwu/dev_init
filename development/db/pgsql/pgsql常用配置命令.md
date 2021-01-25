# pgsql 常用配置命令

## 用户管理

以下所有操作均需要进入 psql 的 shell，进入方式

```sh
sudo su - postgres
psql
```

### 用户相关

创建用户

```sh
create user demo_user with encrypted password '123456';
```

修改密码

```sh
\password
\quit
```

显示用户

```sh
\du
```

删除用户

```sh
drop user demo_user;
```

切换用户

```sh
psql -d demo_db -U demo_user
```

### 库相关

建库

```sh
create database demo_db owner demo_user;
grant all privileges on database demo_db to demo_user;
\c demo_db;
alter schema public owner to demo_user;
grant all privileges on all sequences in schema public to demo_user;
grant all privileges on all tables in schema public to demo_user;

或者，在非psql的shell下，直接用系统命令
createdb -O demo_user demo_db;
```

切换数据库

```sh
\connect demo_db demo_user
```

### 修改 db owner

```sh
alter database xxx owner to yyy;
```

查看数据库, 类似 `show databases`

```sh
select * from pg_database;
```

显示表, 类似 `show tables`

用户自定义的表，如果未经特殊处理，默认都是放在名为 public 的 schema 下

```sh
select * from pg_tables where schemaname = 'public';
```

查看表结构

```sh
\d my_table;
```
