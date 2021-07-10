#!/bin/bash

echo $(/opt/AMDuProf/bin/AMDuProfPcm -m fp -d 1 -a -q | tail -1 | awk -F ',' '{s=0;for(i=1;i<=NF;i++) if(i%2>0) s+=$i ;print s}')*1000000000 | bc