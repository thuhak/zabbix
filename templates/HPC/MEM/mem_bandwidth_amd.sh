#!/bin/bash

echo $(/opt/AMDuProf/bin/AMDuProfPcm -m memory -d 1 -a -q |  awk -F ',' 'END{print $1+$20}')*1073741824 | bc