#!/bin/sh

# Set the following variables in your environment:
# PACMAN_SYNC_WIFI="wlan0 wlan1 ath0"
# PACMAN_SYNC_SSID="linksys attwifi eduroam"

R="`which route` -n"

# Don't sync when offline
if ! $R | cut -f 1 -d' ' | grep 0.0.0.0 > /dev/null; then
    echo No gateway, not synching.
    exit 0
fi

# Don't sync on modem/3G connections
if $R | grep ppp0 > /dev/null; then
    echo PPP detected, not synching.
    exit 0
fi


CHECK='yes'

SSID="wired"
GWIF=`gwif`
for iface in $PACMAN_SYNC_WIFI; do
    if [ "$GWIF" = "$iface" ]; then
	SSID=`ssid $iface`
	_SSID=`echo $SSID | tr ' ' _`
	CHECK='no'
	for name in $PACMAN_SYNC_SSID; do
	    if [ "$name" = "$_SSID" ]; then
		CHECK='yes'
		break 2;
	    fi
	done
    fi
done

if [ "$CHECK" != 'yes' ]; then
    echo Unknown wifi $SSID, not synching.
    exit 0
fi

echo Synching pacman at `date "+%H:%M"` on $SSID...
timeout 30 sudo pacman -Sy > /dev/null 2>&1;
