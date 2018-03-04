#!/bin/sh
info=`pactl list cards | grep "A2DP Sink.*available: yes" -B 40`
bluezcard=`echo "$info" | grep Name | tail -n 1 | egrep -o 'bluez.*'`
if echo "$info" | grep -q "headset_head_unit.*available: yes"; then
    pactl set-card-profile $bluezcard headset_head_unit
else
    pactl set-sink-mute 0 1
    sleep 0.1
    pactl set-card-profile $bluezcard off
    pactl set-sink-mute 0 0
fi
pactl set-card-profile $bluezcard a2dp_sink
