# orm

暂不支持自动建表，需要手动创建

## 配置管理

如果配置 toml 是这样

```toml
[database]
    link  = "mysql:root:root@tcp(127.0.0.1:4407)/aaa"
    debug = true
```

则引用 db 为

```go
db := g.DB()
```

如果配置 toml 是这样

```toml
[database]
    [[database.abc]]
        link = "mysql:root:root@tcp(127.0.0.1:4407)/aaa"
        debug = true
    [[database.xyz]]
        link = "mysql:root:root@tcp(127.0.0.1:4407)/bbb"
        debug = true
```

则引用 db 为

```go
db := g.DB("abc")
```
