# cli

## 说明

客户端的用法

## pgcli

基本用法

```sh
# 提示输入密码
pgcli -h 127.0.0.1 -p 5432 -U demo_user -d demo_db -W

# 通过环境变量
export PGPASSWORD='123456'
pgcli -h 127.0.0.1 -p 5432 -U demo_user -d demo_db

# 这个不需要环境变量
pgcli postgres://postgres:pg123456@127.0.0.1:5432/demo_db
```

用于自动化

```sh
# ~/.pgpass
127.0.0.1:5432:demo_db:demo_user:123456
```

```sh
chmod 600 ~/.pgpass
pgcli -h 127.0.0.1 -U demo_user -d demo_db
```

## psql

官方工具，密码验证规则和上面的完全一致

```sh
psql -h 10.0.2.199 -U replica -d postgres
```
