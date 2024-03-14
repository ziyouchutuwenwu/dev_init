# mysql 集群

## 步骤

### 准备

```sh
docker pull mysql:5.7.22
```

```sh
mkdir -p /opt/mysql_cluster/master/conf/
mkdir -p /opt/mysql_cluster/master/data/

mkdir -p /opt/mysql_cluster/slave/conf/
mkdir -p /opt/mysql_cluster/slave/data/
```

### 配置文件

master

```sh
vim /opt/mysql_cluster/master/conf/my.cnf
```

```conf
[mysqld]
# 用于标识不同的数据库服务器，而且唯一
server_id = 1
log-bin= mysql-bin

# 指定同步的数据库， 如果不配置，就同步所有db
# binlog-do-db=user

# 忽略记录二进制日志的数据库
replicate-ignore-db=mysql
replicate-ignore-db=sys
replicate-ignore-db=information_schema
replicate-ignore-db=performance_schema
```

slave

```sh
vim /opt/mysql_cluster/slave/conf/my.cnf
```

```conf
[mysqld]
server_id = 2
log-bin= mysql-bin

# 忽略记录二进制日志的数据库
replicate-ignore-db=mysql
replicate-ignore-db=sys
replicate-ignore-db=information_schema
replicate-ignore-db=performance_schema
```

### 启动

```sh
docker network create --driver=bridge mysql
docker run -d --name mysql-master -p 3306:3306 --memory 12G \
  --network=mysql -h "mysql-master" -e MYSQL_ROOT_PASSWORD=root --privileged=true \
  -v /opt/mysql_cluster/master/data:/var/lib/mysql \
  -v /opt/mysql_cluster/master/conf/my.cnf:/etc/mysql/my.cnf \
  mysql:5.7.22

docker run -d --name mysql-slave -p 4407:3306 --memory 12G \
  --network=mysql -h "mysql-slave" -e MYSQL_ROOT_PASSWORD=root --privileged=true \
  -v /opt/mysql_cluster/slave/data:/var/lib/mysql \
  -v /opt/mysql_cluster/slave/conf/my.cnf:/etc/mysql/my.cnf \
  mysql:5.7.22
```

### 主从操作

#### 授权用于复制的用户

授权用户在任何服务器上作为从库的角色来复制主库

```sql
create user replica_user;
grant REPLICATION SLAVE on *.* to 'replica_user'@'%' IDENTIFIED by 'replica_pass';
flush privileges;
```

#### 主库

主库查询目前的位置

```sql
show master status;
```

返回

```sql
+------------------+----------+--------------+------------------+-------------------+
| File             | Position | Binlog_Do_DB | Binlog_Ignore_DB | Executed_Gtid_Set |
+------------------+----------+--------------+------------------+-------------------+
| mysql-bin.000009 |      154 |              |                  |                   |
+------------------+----------+--------------+------------------+-------------------+
1 row in set (0.00 sec)
```

#### 从库

启动 slave 模式

```sql
change master to master_host='mysql-master', master_port=3306, master_user='replica_user', master_password='replica_pass', master_log_file='mysql-bin.000009', master_log_pos=154;
start slave;
```

查看

```sql
show slave status\G
```

查看, 看到以下两个都为 yes

```sh
Slave_IO_Running
Slave_SQL_Running
```

#### 从切换为主

```sh
stop slave io_thread;
```

查看状态

```sh
show processlist\G
```

看到类似下面的说明完成了

```sh
State: Slave has read all relay log; waiting for more updates
```

重置

```sh
stop slave; reset slave all; reset master;
```

执行主库操作

#### 主切换为从

重置

```sh
stop slave; reset slave all; reset master;
```

执行从库操作
