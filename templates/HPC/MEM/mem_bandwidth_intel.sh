#!/bin/bash

echo $(pcm-memory -partial -csv -nc  -i=1 2>/dev/null | awk -F ',' 'END{print $13}' | tr -d ' ')*1048576 | bc