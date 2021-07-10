#!/usr/bin/env python3
"""
pbs queue info monitor
"""
import json
import subprocess
from collections import defaultdict

jobdata = json.loads(subprocess.check_output('/opt/pbs/bin/qstat -f -F json', shell=True))['Jobs']
raw_nodedata = json.loads(subprocess.check_output('/opt/pbs/bin/pbsnodes -Sa -F json', shell=True))['nodes']

queue_info = defaultdict(lambda: defaultdict(int))
main_info = defaultdict(int)

for node, data in raw_nodedata.items():
    queue = data['queue']
    queue_info[queue]['total_cpus'] += data['ncpus']
    main_info['total_cpus'] += data['ncpus']


for job, data in jobdata.items():
    queue = data['queue']
    status = data['job_state']
    cpus = data["Resource_List"]["ncpus"]
    if status == 'R':
        queue_info[queue]['running_jobs'] += 1
        queue_info[queue]['using_cpus'] += cpus
        main_info['running_jobs'] += 1
        main_info['using_cpus'] += cpus

    elif status == 'Q':
        queue_info[queue]['waiting_jobs'] += 1
        queue_info[queue]['waiting_cpus'] += cpus
        main_info['waiting_jobs'] += 1
        main_info['waiting_cpus'] += cpus


if main_info['running_jobs'] == 0:
    main_info['running_rate'] = 0
else:
    main_info['running_rate'] = main_info['running_jobs'] * 100.0 /(main_info['running_jobs'] + main_info['waiting_jobs'])

if main_info['total_cpus'] == 0:
    main_info['cpu_usage_rate'] = 0
else:
    main_info['cpu_usage_rate'] = (main_info['using_cpus'] + main_info['waiting_cpus']) * 100.0 / main_info['total_cpus']


for queue, data in queue_info.items():
    if data['running_jobs'] == 0:
        queue_info[queue]['waiting_jobs'] += 0
        running_rate = 0
    else:
        running_rate = data['running_jobs'] * 100.0/(data['running_jobs'] + data['waiting_jobs'])
    queue_info[queue]['running_rate'] = running_rate
    if data['total_cpus'] == 0:
        cpu_usages = 0
        queue_info[queue]['waiting_cpus'] += 0
    else:
        cpu_usages = (data['using_cpus'] + data['waiting_cpus']) * 100.0/data['total_cpus']
    queue_info[queue]['cpu_usage_rate'] = cpu_usages

result = {
    'main': main_info,
    'queue': queue_info
}


print(json.dumps(result, indent=True))