# 自增 id

## 用法

查看当前序列

```sql
select nextval('xxx_id_seq');
```

修改

```sql
alter sequence xxx_id_seq restart with 1;
```

清空记录并且重置

```sql
truncate table xxx restart identity cascade;
```

查找表里面最大 id

```sql
select max(id) from xxx;
```

设置为最大 id

```sql
select setval('xxx_id_seq', max(id)) from xxx;
```
