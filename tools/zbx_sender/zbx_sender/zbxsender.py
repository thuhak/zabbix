#!/usr/bin/env python3
import json
import time
import socket


class Metric:
    __slots__ = ['key', 'value', 'clock']

    def __init__(self, key, value, clock=None):
        self.key = key
        self.value = str(value)
        self.clock = clock or ('%d' % time.time())

    def __repr__(self):
        return "key:{},value:{},clock:{}".format(self.key, self.value, self.clock)


class ZbxSender:

    def __init__(self, host=None, zbxhost='127.0.0.1', zbxport=10051, DEBUG=False):
        self.host = host or socket.gethostname()
        self.zbx = (zbxhost, zbxport)
        self.sock = None
        self.DEBUG = DEBUG

    def __enter__(self):
        if self.sock is not None:
            raise RuntimeError('Already connected')
        self.sock = socket.socket()
        self.sock.connect(self.zbx)
        return self

    def __exit__(self, *args):
        self.sock.close()
        self.sock = None

    def send(self, metrics):
        if self.sock is None:
            raise RuntimeError('You should make connection first')
        if isinstance(metrics, Metric):
            metrics = [metrics]
        data = []
        for m in metrics:
            data.append(
                {"host": self.host, "key": m.key, "value": m.value, "clock": m.clock})
        json_data = json.dumps({"request": "sender data", "data": data})
        data_len = len(json_data).to_bytes(8, 'little')
        packet = memoryview(b'ZBXD\x01' + data_len + json_data.encode('ascii'))
        self.sock.sendall(packet)
        resp_hdr = self.sock.recv(13)
        if not resp_hdr.startswith(b'ZBXD\x01') or len(resp_hdr) != 13:
            raise RuntimeError('Wrong zabbix response')
        resp_body_len = int.from_bytes(memoryview(resp_hdr[5:]), 'little')
        resp_body = self.sock.recv(resp_body_len)
        resp = json.loads(resp_body.decode('ascii'))
        if resp.get('response') != 'success':
            print('Got error from Zabbix: %s' % resp)
            return False
        elif self.DEBUG:
            print(resp.get('info'))
        return True
