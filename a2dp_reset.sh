#!/bin/sh
BLUEZCARD=`pactl list cards | grep "A2DP Sink.*available: yes" -B 100 | grep Name | tail -n 1 | egrep -o 'bluez.*'`
pactl set-card-profile $BLUEZCARD headset_head_unit
pactl set-card-profile $BLUEZCARD a2dp_sink
