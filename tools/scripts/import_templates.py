"""
import zabbix templates
"""
# author: thuhak.zhou@nio.com
from glob import glob
import os
from argparse import ArgumentParser
from pyzabbix import ZabbixAPI


parser = ArgumentParser()
parser.add_argument('host', help='zabbix url')
parser.add_argument('--template', '-t', required=True, help='zabbix templates directory')
parser.add_argument('--user', '-u', required=True, help='user')
parser.add_argument('--password', '-p', help='password')

args = parser.parse_args()
zapi = ZabbixAPI(args.host)
zapi.login(args.user, args.password)

rules = {
    'applications': {
        'createMissing': True,
    },
    'discoveryRules': {
        'createMissing': True,
        'updateExisting': True
    },
    'graphs': {
        'createMissing': True,
        'updateExisting': True
    },
    'groups': {
        'createMissing': True
    },
    'hosts': {
        'createMissing': True,
        'updateExisting': True
    },
    'images': {
        'createMissing': True,
        'updateExisting': True
    },
    'items': {
        'createMissing': True,
        'updateExisting': True
    },
    'maps': {
        'createMissing': True,
        'updateExisting': True
    },
    'screens': {
        'createMissing': True,
        'updateExisting': True
    },
    'templateLinkage': {
        'createMissing': True,
    },
    'templates': {
        'createMissing': True,
        'updateExisting': True
    },
    'templateScreens': {
        'createMissing': True,
        'updateExisting': True
    },
    'triggers': {
        'createMissing': True,
        'updateExisting': True
    },
    'valueMaps': {
        'createMissing': True,
        'updateExisting': True
    },
}

name = os.path.basename(args.template)

for template in glob(os.path.join(args.template, '*.xml')):
    with open(template) as f:
        source = f.read()
    zapi.confimport('xml', source, rules)