# json 查询

## 准备工作

```sql
drop table if exists demo_table;
create table "demo_table" ("id" bigserial, "demo_json" jsonb, PRIMARY KEY ("id"));

insert into demo_table(demo_json) values('{"aaa" : "value1", "bbb": "value2"}');
insert into demo_table(demo_json) values('{"aaa" : "value3", "bbb": "value4"}');
insert into demo_table(demo_json) values('{"aaa" : "value5", "bbb": "value6"}');
```

## 创建索引

```sql
create index on demo_table((demo_json->>'aaa'));
create index demo_index on demo_table (((demo_json->>'aaa') :: text), (demo_json->>'bbb'));
```

## 查询

like 查询

```sql
select
  id,
  demo_json->'aaa' as json_aaa,
  demo_json
from
  demo_table
where
  (demo_json->'aaa')::text like '%value%';
```

字段匹配查询

```sql
select
  id,
  demo_json->'aaa' as json_aaa,
  demo_json
from
  demo_table
where
  demo_json->>'aaa' = 'value1';
```

## 更新

更新整个 json 字段

```sql
update
  demo_table
set
  demo_json = '{"ccc": "7"}'
where
 id = 3;
```

更新 json 其中一部分

```sql
update
  demo_table
set
  demo_json = demo_json || '{"new_key1":"new_value1","new_key2":"new_value2"}'
where
 id = 2;
```
