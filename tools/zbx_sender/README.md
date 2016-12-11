zabbix sender 的python实现
=========================

如果不希望使用zabbix自带的zabbix_sender进行数据发送，
可以使用python原生的sender。方便嵌入到python代码中。
zabbix通信细节见zabbix官方文档[Passive and active agent checks](https://www.zabbix.com/documentation/3.2/manual/appendix/items/activepassive)

我只做了python3的部分。

## 安装

使用python3 setup.py install进行安装

## 使用方法

- zabbix服务器地址为192.168.1.1（默认参数127.0.0.1）
- 想要发送的主机名为hostname(默认为本机机器名)
- 想要发送的key和value为'traptest'和123，456

样式代码如下：

```python
senddata=[Metric('traptest','123'),Metric('traptest','456')]
with ZbxSender(host='test',zbxhost='192.168.1.1') as zbx:
    zbx.send(senddata)
```
