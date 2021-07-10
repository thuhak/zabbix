#!/usr/bin/python3.6
from configparser import ConfigParser
from argparse import ArgumentParser

config_file = '/etc/odbc.ini'
parser = ArgumentParser()
parser.add_argument('name', help='name of dsn')
parser.add_argument('--type', '-t', choices=['sqlserver', 'mysql', 'postgresql'], required=True, help='type of server')
parser.add_argument('--server', '-s', required=True, help='server ip or hostname')
parser.add_argument('--port', '-p', type=int, help='port of server')

type_map = {'sqlserver': ['FreeTDS', 1433],
            'mysql': ['MySQL', 3306],
            'postgresql': ['PostgreSQL', 5432]
            }

args = parser.parse_args()
name = args.name
driver_type = type_map[args.type][0]
server = args.server
port = args.port or type_map[args.type][1]

config = ConfigParser()
config.read(config_file)

config[name] = {'Driver': driver_type, 'Server': server, 'Port': port}

with open(config_file, 'w') as f:
    config.write(f)