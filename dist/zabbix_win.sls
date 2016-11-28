stopzabbix:
    service.dead:
      - name: "Zabbix Agent"

C:\zabbix_agent:
    file.recurse:
{% if grains['cpuarch'] == 'AMD64' %}
        - source: salt://zabbix/agent/win64
{% elif grains['cpuarch'] == 'x86' %}
        - source: salt://zabbix/agent/win32
{% endif %}
        - require:
            - service: stopzabbix
        
C:\zabbix_agent\zabbix.conf:
    file.managed:
        - source: salt://zabbix/agent/zabbix_agentd_win.conf
        - template: jinja
        - context:
           server: {{ pillar['zabbix']['server'] }} 
           active_server: {{ pillar['zabbix']['active_server'] }}
        - require:
           - file: C:\zabbix_agent

installservice:
    cmd.script:
      - source: salt://zabbix/agent/installservice.ps1
      - shell: powershell
      - stateful: True
      - require:
          - file: C:\zabbix_agent\zabbix.conf

startservice:
  service.running:
    - name: "Zabbix Agent"
    - enable: True
    - require:
        - cmd: installservice
    

