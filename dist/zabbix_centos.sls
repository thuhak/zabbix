zabbix-agent:
    pkg:
      - installed

/etc/zabbix/zabbix_agentd.conf:
    file.managed:
      - source: salt://zabbix/agent/zabbix_agentd_lin.conf
      - template: jinja
      - context:
           server: {{ pillar['zabbix']['server'] }} 
           active_server: {{ pillar['zabbix']['active_server'] }}
      - require:
          - pkg: zabbix-agent

zabbix-agent:
    service.running:
      - enable: True
      - require:
         - pkg: zabbix-agent
      - watching:
         - file: /etc/zabbix/zabbix_agentd.conf 
