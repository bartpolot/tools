#!/bin/sh

do_sync ()
{
    echo Synching pacman at `date "+%H:%M"` on $network...
    timeout 30 sudo pacman -Sy > /dev/null 2>&1;
    exit 0
}


PATH="`dirname $0`:$PATH"

# Set the following variables in your environment:
# PACMAN_SYNC_ETH="eth0 en0"
# PACMAN_SYNC_WIFI="wlan0 wlan1 ath0"
# PACMAN_SYNC_SSID="linksys attwifi eduroam"
config_file="$HOME/.config/pacman_sync.conf"
if [ -f $config_file ]; then
    source $config_file
fi

r="`which route` -n"

# Don't sync when offline
if ! $r | cut -f 1 -d' ' | grep -q 0.0.0.0; then
    echo No gateway, not synching.
    exit 0
fi

# Don't sync on modem/3G connections
if $r | grep -q ppp0; then
    echo PPP detected, not synching.
    exit 0
fi

gwif=`gwif`
network='unknown'
for iface in $PACMAN_SYNC_ETH; do
    if [ "$gwif" = "$iface" ]; then
	network="wired $iface"
	do_sync
    fi
done

if [ "$check" != "yes" ]; then
    for iface in $PACMAN_SYNC_WIFI; do
	if [ "$gwif" = "$iface" ]; then
	    network=`ssid $iface`
	    _network=`echo $network | tr ' ' _`
	    for name in $PACMAN_SYNC_SSID; do
		if [ "$name" = "$_network" ]; then
		    network="wifi $network"
		    do_sync
		fi
	    done
	    echo Unknown wifi $network, not synching.
	    exit 0
	fi
    done
fi

echo Unknown default interface $gwif, not synching.
