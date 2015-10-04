#!/bin/bash

set -x

DEFAULT_IF=ra0

# Command line args
if [ $# -lt 1 ]; then
    echo usage $0 CONF_DIR [IFACE] [--secure];
    exit 1;
elif [ $# -lt 2 ]; then
    IFACE=ra0;
else
    IFACE=$2;
fi

# Configuration dir
CONF_DIR=${1%/}
if [ ! -d "$CONF_DIR" ]; then
    echo $CONF_DIR is not a valid config directory
fi
mkdir -p .run/$CONF_DIR || exit 1

# IP for network
if [ -f "$CONF_DIR/IP" ]; then
    LINE=`cat $CONF_DIR/IP`
    PREFIX=${LINE%.*}
    SUBNET=${LINE##*.}
else
    PREFIX=192.168
    SUBNET=8
fi
while ip addr | grep "192\.168\.$SUBNET\." > /dev/null; do
    SUBNET=$((SUBNET+1))
done
ifconfig $IFACE $PREFIX.$SUBNET.1 up
echo PREFIX=$PREFIX SUBNET=$SUBNET


# Gateway
GW=`ip route | grep default | cut -d' ' -f 5`
if [ -z "$GW" ]; then
    echo Could not find gateway interface. Network won\'t have internet connectivity.
    sleep 2
fi

cat /proc/sys/net/ipv4/ip_forward > .run/$CONF_DIR/ip_fwd.$$
echo 1 > /proc/sys/net/ipv4/ip_forward

if [ $# -lt 3 -o "$3" != "--secure" ]; then
    iptables -A INPUT -i $IFACE -p udp -j ACCEPT
    iptables -A INPUT -i $IFACE -j DROP
    iptables -A FORWARD -i $IFACE -d 192.168.0.0/16 -j DROP
    iptables -A FORWARD -i $IFACE -d 172.24.0.0/16 -j DROP
    iptables -A FORWARD -i $IFACE -d 10.0.0.0/8 -j DROP
fi

[ -n "$GW" ] && iptables -t nat -A POSTROUTING -s $PREFIX.$SUBNET.0/24 -o $GW -j MASQUERADE

sed -e "s/INTERFACE/$IFACE/g" $CONF_DIR/hostapd.conf > .run/$CONF_DIR/hostapd.$$.conf
sed -e "s/INTERFACE/$IFACE/g;s/SUBNET/$SUBNET/g;s/PREFIX/$PREFIX/g" $CONF_DIR/dnsmasq.conf > .run/$CONF_DIR/dnsmasq.$$.conf
sed -e "s/UNIQ/$$/g; s/CONFIG/$CONF_DIR/" .WAP > .run/$CONF_DIR/WAP.$$

screen -c .run/$CONF_DIR/WAP.$$

mv .run/$CONF_DIR/WAP.$$ .run/$CONF_DIR/WAP.old
mv .run/$CONF_DIR/dnsmasq.$$.conf .run/$CONF_DIR/dnsmasq.conf.old
mv .run/$CONF_DIR/hostapd.$$.conf .run/$CONF_DIR/hostapd.conf.old

[ -n "$GW" ] && iptables -t nat -D POSTROUTING -s $PREFIX.$SUBNET.0/24 -o $GW -j MASQUERADE

if [ $# -lt 3 -o "$3" != "--secure" ]; then
    iptables -D FORWARD -i $IFACE -d 192.168.0.0/16 -j DROP
    iptables -D FORWARD -i $IFACE -d 172.24.0.0/16 -j DROP
    iptables -D FORWARD -i $IFACE -d 10.0.0.0/8 -j DROP
    iptables -D INPUT -i $IFACE -p udp -j ACCEPT
    iptables -D INPUT -i $IFACE -j DROP
fi

cat .run/$CONF_DIR/ip_fwd.$$ > /proc/sys/net/ipv4/ip_forward
mv  .run/$CONF_DIR/ip_fwd.$$ .run/$CONF_DIR/ip_fwd.old

ifconfig $IFACE 0.0.0.0
ifconfig $IFACE down
