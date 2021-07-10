from pyzabbix import ZabbixAPI, ZabbixAPIException


# change config
user = 'zabbix'
passwd = 'zabbix'
host = 'http://zabbix/zabbix'

zapi = ZabbixAPI(host)
zapi.login(user, passwd)


def get_media_id(name):
    result = zapi.mediatype.get(filter={'name': name})
    return result[0].mediatypeid


def add_hostgroup(name, esc_period=15, mediatypeid=1):
    """
    add one host group, two roles, one action
    """
    # add hostgroup
    try:
        groupid = zapi.hostgroup.create(name=name)['groupids'][0]
    except ZabbixAPIException as e:
        return {'result': False, 'comment': e.error['data']}
    # add two roles
    rights = {'permission': 3, 'id': groupid}
    usergroup_main = zapi.usergroup.create(name=f'{name}_main', rights=rights)['usrgrpids'][0]
    usergroup_backup = zapi.usergroup.create(name=f'{name}_backup', rights=rights)['usrgrpids'][0]
    # add action
    action_filter = {'evaltype': 0,
                     'conditions': [
                         {
                             'conditiontype': 4,  # trigger severity is greater than equals average
                             'operator': 5,
                             'value': '3'
                         },
                         {
                             'conditiontype': 0,  # host group equals the new group
                             'operator': 0,
                             'value': groupid
                         }
                     ]
                     }
    operations = [
        {
            'operationtype': 0,
            'esc_step_from': 1,
            'esc_step_to': 1,
            'opmessage_grp': [
                {'usrgrpid': usergroup_main},
            ],
            'opmessage': {
                'default_msg': 1,
                'mediatypid': mediatypeid
            }
        },
        {
            'operationtype': 0,
            'esc_step_from': 2,
            'esc_step_to': 2,
            'opmessage_grp': [
                {'usrgrpid': usergroup_backup}
            ],
            'opmessage': {
                'default_msg': 1,
                'mediatypeid': mediatypeid
            },
            'opconditions': [
                {
                    'conditiontype': 14,
                    'operator': 0,
                    'value': '0'
                }
            ]
        }
    ]
    recovery_opertions = [
        {
            'operationtype': "11",
            'opmessage': {
                'default_msg': 1
            }
        }
    ]
    zapi.action.create(name=name, eventsource=0, esc_period=f'{esc_period}m', status=0, filter=action_filter,
                       operations=operations, recovery_opertions=recovery_opertions)
    return {'result': True}


def delete_hostgroup(name):
    """
    delete certain host group
    """
    try:
        actionid = zapi.action.get(filter={'name': name})[0]['actionid']
        zapi.action.delete(actionid)
    except Exception:
        pass
    try:
        usergroups = zapi.usergroup.get(filter={'name': [f'{name}_main', f'{name}_backup']})
        usergroup_ids = [x['usrgrpid'] for x in usergroups]
        zapi.usergroup.delete(*usergroup_ids)
    except Exception:
        pass
    try:
        hostgroup_id = zapi.hostgroup.get(filter={'name': name})[0]['groupid']
        zapi.hostgroup.delete(hostgroup_id)
    except Exception:
        pass


def setname(host, name):
    try:
        ob = zapi.host.get(filter={'host': host}, output=['hostid'])[0]['hostid']
    except Exception as e:
        return
    zapi.host.update(hostid=ob, name=name)


def addsnmp(host, snmp_ip):
    try:
        ob = zapi.host.get(filter={'host': host}, output=['hostid'])[0]['hostid']
    except Exception as e:
        return
    zapi.hostinterface.create(hostid=ob, dns='', ip=snmp_ip, main=1, type=2, port="161", useip=1)


