# zabbix postgre数据库分区方案

## 前言

zabbix默认所有的history和trends表都按照数据类型放在同一张表里面。housekeeper使用delete进行删除，导致数据清除十分缓慢。而且也会因为严重的碎片化降低整体性能。
把整history和trends表按照时间进行分区后，想要删除数据直接使用drop子表进行删除。

zabbix wiki里面有几个postgre的分区方案，看了以后觉得使用方法和格式不是很满意,于是自己又重新写了一个。

## 准备

### postgre的要求

过程语言主体部分是由python3写成的(有些方法不兼容python2)，因此需要为postgre安装plpython3u扩展。

如果使用手工编译postgre的方法，可以使用`./configure --with-python PYTHON=/usr/bin/python3`来编译。

然后通过SQL：`CREATE LANGUAGE plython3u`来建立python3的过程语言

### postgre的配置

postgre有一个规划器的参数constrain_exclusion和表分区有关，建议设置成on。排除分区表的扫描。

### 需要的python库

过程语言依赖python-dateutil和jinja2

可以使用`pip3 install python-dateutil jinja2`进行安装

## 代码说明

### schema和tablespace

我选择新建了一个schema来存放子表，浏览方便一些，同时也支持使用其他表空间存放子表.可以使用tablespace参数来指定表空间名称

### WAL

我关闭了history和trends表的预写式日志功能，以增加性能。可以在代码中把UNLOGGED选项去除

### 分区方法

对于history表，采用按天进行分区，每天的分区后缀为_yyyymmdd;对于trends表，采用按月分区，每个月的后缀为_yyyymm。

history_old,history_new,trend_old,trend_new这四个参数用来指定存放多少个过去的子表和未来的子表。每次运行会以当天日期为中心进行扩展和删除。
如果使用zabbix_make_partition(0,0,0,0)，则清除所有的分区数据，恢复未分区状态。
为了防止误操作，禁止使用负数。

## 客户端脚本

zabbix_db_maintenace.py是附带的执行脚本。日志可以用zabbix来进行过程监控