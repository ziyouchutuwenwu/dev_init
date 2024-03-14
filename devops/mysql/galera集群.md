# galera 集群

## 安装

```sh
sudo apt install mariadb-server
```

设置密码

```sh
sudo mysql -uroot
use mysql;
set password for root=password('xxxx');
flush privileges;
quit;
```

## 集群配置

在每个节点设置配置文件

```sh
vim /etc/mysql/conf.d/galera.cnf
hosts 和 hostname 里面做好设置
```

```conf
[mysqld]
binlog_format=row
default-storage-engine=innodb

#主键自增修改为交叉模式
innodb_autoinc_lock_mode=2
#关闭此参数会提升性能
innodb_flush_log_at_trx_commit=0
bind-address=0.0.0.0



[galera]
wsrep_on=ON
# 各节点应用完事务才返回查询请求，可以避免脏读
# 3.6 以后，用 wsrep_sync_wait
wsrep_causal_reads=ON
# 为没有主键的表自动生成主键
wsrep_certify_nonPK=ON
wsrep_provider=/usr/lib/galera/libgalera_smm.so
wsrep_cluster_name=cluster1
# gcomm 后面的节点之间，不能有空格
wsrep_cluster_address="gcomm://node1,node2,node3"

#并行应用Galera集群的从属线程数，如果经常出现一致性问题，请设置为1
wsrep_slave_threads=1

#wsrep_sst_method=mariabackup
wsrep_sst_method=rsync

#集群同步开启验证
wsrep_sst_auth='root:123456'

# 每个节点的配置
wsrep_node_address="192.168.56.11"
wsrep_node_name="node1"
```

## 启动

第一次启动

主节点

```sh
sudo galera_new_cluster
```

其他节点

```sh
systemctl start mariadb
```

如果启动失败，查看 log

```sh
tail -f /var/log/mysql/error.log
```

## 查看状态

```sh
mysql -u root -proot -e "show status like 'wsrep_cluster_size'"
```

## 集群故障恢复

如果全部宕机，需要在每个节点

```sh
sudo cat /var/lib/mysql/grastate.dat | grep safe_to_bootstrap
```

看哪个是 1， 是 1 的主机

```sh
galera_new_cluster
```

其他

```sh
systemctl start mariadb
```

## 现有数据迁移

原始数据导出

```sh
mysqldump -u root -p --skip-create-options --all-databases > migration.sql
```

导入

```sh
mysql -u root -p < migration.sql
```
