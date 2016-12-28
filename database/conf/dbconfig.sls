# zabbix数据库配置

## 内核参数设置

vm.swappiness: # 关闭交换分区
  sysctl.present:
    - value: 0 

vm.dirty_ratio: # 如果脏页比率超过95，调用fsync调用需要主动回写
  sysctl.present:
    - value: 95

vm.dirty_expire_centisecs: # 30秒以上的旧页被回写
  sysctl.present:
    - value: 3000

vm.dirty_writeback_centisecs: # 每秒调用pdflush进行脏页回写
  sysctl.present:
    - value: 100

fs.aio-max-nr: # 最大同时异步IO数
  sysctl.present:
    - value: 1048576 #1024 x 1024

fs.file-max:  # 最大文件打开数
  sysctl.present:
    - value: 1048576

## 文件系统参数

/data: # 普通数据
  mount.mounted:
    - device: /dev/sdb1
    - fstype: ext3
    - mkmnt: False
    - opts: defaults,noatime,nodiratime,data=ordered # 关闭atime以增加性能
    - user: postgres

/zabbix-history: # 历史,趋势数据表表空间分区
  mount.mounted:
    - device: /dev/sdc1
    - fstype: ext3
    - mkmnt: False
    - opts: defaults,noatime,nodiratime,data=writeback # 关闭atime并把日志模式设置成writeback用以获得最佳性能
    - user: postgres
