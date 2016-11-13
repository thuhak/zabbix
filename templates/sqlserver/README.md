# sqlserver模板

是[Template MS SQL 2012](https://share.zabbix.com/databases/micorsoft-sql-server/template-ms-sql-2012)的汉化版本，同时用数据库监控代理了客户端脚本。

### 功能

55个监控项，1个自动发现规则，14个图形，1个聚合图形

### 数据库监控

需要在服务器端开启unixODBC功能，配置并安装freetds

### 宏

- {$DB_USER}: 数据库用户，需要有对sys.sysdatabases的读权限
- {$DB_PASS}：数据库密码
- {$DSN}:zabbix服务器端配置的dsn