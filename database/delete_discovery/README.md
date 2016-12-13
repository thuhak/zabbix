# 删除发现规则中主机

zabbix通过主动扫描发现的主机在手工进行删除后，在下一次扫描的时候还会被加入。比较麻烦。

可以使用两种方法进行删除。一种是手工调用`delete_dhost.sql`的函数，另一种则是使用`delete_discovery_trigger.sql`中的触发器，进行自动删除。