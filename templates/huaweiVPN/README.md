# 华为svn2260 VPN监控模板

### 功能

- 系统序列号、版本监控
- CPU、内存使用监控
- ssl vpn在线人数监控

### 宏

根据需要，设置如下宏：

- {$SNMP_COMMUNITY}:snmp v2 团体字
- {$CPU_H}:CPU阈值
- {$SSLVPN_H}:VPN人数阈值
- {$SSLVPN_R}:VPN人数恢复阈值

### 其他：

ping和网卡监控可以连接其他通用模板。
网卡需要正则表达式过滤掉NULL和Loop端口