#!/bin/bash
for f in /sys/class/power_supply/BAT*/power_now; do
    nW=`cat $f`;
    W=`bc <<< "scale=2; $nW / 1000000"`
    printf "%7sW\n" $W
done
