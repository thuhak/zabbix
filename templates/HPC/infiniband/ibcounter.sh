#!/bin/bash

/usr/sbin/perfquery | tr '.' ' ' | tr -d ':' | awk 'NR>1' | /opt/scripts/d2j