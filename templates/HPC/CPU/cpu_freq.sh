#!/bin/bash

cpupower monitor -m "Mperf" | awk -F '|' 'NR>2{print $6}' | sed 's/ //g' | awk '{x+=$1} END {print x/NR}'