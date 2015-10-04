#!/bin/bash


DEFAULT_IF=wifi0

# Command line args
if [ $# -lt 1 ]; then
    echo usage $0 CONF_DIR [IFACE] [--secure];
    exit 1;
elif [ $# -lt 2 ]; then
    IFACE=$DEFAULT_IF;
else
    IFACE=$2;
fi


# Configuration dir
CONF_DIR=${1%/}
CONF_NAME=`basename $CONF_DIR`
ROOT_DIR=`dirname $0`
CONF_DIR="$ROOT_DIR/$CONF_NAME"
if [ ! -d "$CONF_DIR" ]; then
    echo $CONF_DIR is not a valid config directory
    exit 1
fi


# Runtime dir to store the config files
if [ -z $XDG_RUNTIME_DIR ]; then
    RUN_DIR="/tmp/ap/$CONF_NAME"
else
    RUN_DIR="$XDG_RUNTIME_DIR/ap/$CONF_NAME"
fi
mkdir -p $RUN_DIR || exit 1


# IP for the network
if [ -f "$CONF_DIR/IP" ]; then
    LINE=`cat $CONF_DIR/IP`
    PREFIX=${LINE%.*}
    SUBNET=${LINE##*.}
else
    PREFIX=192.168
    SUBNET=8
fi

while ip addr | grep "$PREFIX\.$SUBNET\." > /dev/null; do
    SUBNET=$((SUBNET+1))
done
echo PREFIX=$PREFIX SUBNET=$SUBNET

P=`echo $PREFIX | tr . _`
tmux_session="ap-$CONF_NAME-${P}_${SUBNET}_0"
if [ -n "$TMUX" ]; then
    tmux rename-window $tmux_session
else
    tmux new-session -s $tmux_session $0 $@
    exit
fi
ifconfig $IFACE $PREFIX.$SUBNET.1/24 up





# Gateway
GW=`ip route | grep default | cut -d' ' -f 5`
if [ -z "$GW" ]; then
    echo Could not find gateway interface. Network won\'t have internet connectivity.
    sleep 2
fi


# Save ip_forward status
cat /proc/sys/net/ipv4/ip_forward > $RUN_DIR/ip_fwd.$$
echo 1 > /proc/sys/net/ipv4/ip_forward


# If --secure, don't allow incoming traffic
if [ $# -lt 3 -o "$3" != "--secure" ]; then
    iptables -A INPUT -i $IFACE -p udp --dport 53 -j ACCEPT
    iptables -A INPUT -i $IFACE -p udp --dport 67 -j ACCEPT
    iptables -A INPUT -i $IFACE -j DROP
    iptables -A FORWARD -i $IFACE -d 192.168.0.0/16 -j DROP
    iptables -A FORWARD -i $IFACE -d 172.24.0.0/16 -j DROP
    iptables -A FORWARD -i $IFACE -d 10.0.0.0/8 -j DROP
fi


# Do NAT unless disabled or no gateway
[ -n "$GW" -a ! -f $CONF_DIR/no_nat ] && iptables -t nat -A POSTROUTING -s $PREFIX.$SUBNET.0/24 -o $GW -j MASQUERADE


##########################################################

sed -e "s/INTERFACE/$IFACE/g" $CONF_DIR/hostapd.conf > $RUN_DIR/hostapd.$$.conf
sed -e "s/INTERFACE/$IFACE/g;s/SUBNET/$SUBNET/g;s/PREFIX/$PREFIX/g" $CONF_DIR/dnsmasq.conf > $RUN_DIR/dnsmasq.$$.conf

OLDTMUX=$TMUX
unset TMUX

tmux new-session -d -s __$tmux_session

tmux rename-window -t __$tmux_session "DAEMON $tmux_session"
tmux send-keys     -t __$tmux_session "hostapd -P $RUN_DIR/hostapd.$$.pid $RUN_DIR/hostapd.$$.conf" "C-m"
tmux pipe-pane     -t __$tmux_session -o 'cat >> $RUN_DIR/hostapd.$$.log'


DNSMASQ_OPT="--keep-in-foreground"
DNSMASQ_OPT="$DNSMASQ_OPT --log-queries"
DNSMASQ_OPT="$DNSMASQ_OPT --log-facility=-" # stderr
DNSMASQ_OPT="$DNSMASQ_OPT --conf-file=$RUN_DIR/dnsmasq.$$.conf"
DNSMASQ_OPT="$DNSMASQ_OPT --pid-file=$RUN_DIR/dnsmasq.$$.pid"
tmux split-window  -t __$tmux_session -h
tmux send-keys     -t __$tmux_session "dnsmasq $DNSMASQ_OPT" "C-m"
tmux pipe-pane     -t __$tmux_session -o 'cat >> $RUN_DIR/dnsmasq.$$.log'

tmux -2 attach-session -t __$tmux_session

TMUX=$OLDTMUX

##########################################################


mv $RUN_DIR/dnsmasq.$$.conf $RUN_DIR/dnsmasq.conf.old
mv $RUN_DIR/hostapd.$$.conf $RUN_DIR/hostapd.conf.old

[ -n "$GW" -a ! -f $CONF_DIR/no_nat ] && iptables -t nat -D POSTROUTING -s $PREFIX.$SUBNET.0/24 -o $GW -j MASQUERADE

if [ $# -lt 3 -o "$3" != "--secure" ]; then
    iptables -D FORWARD -i $IFACE -d 192.168.0.0/16 -j DROP
    iptables -D FORWARD -i $IFACE -d 172.24.0.0/16 -j DROP
    iptables -D FORWARD -i $IFACE -d 10.0.0.0/8 -j DROP
    iptables -D INPUT -i $IFACE -p udp --dport 67 -j ACCEPT
    iptables -D INPUT -i $IFACE -p udp --dport 53 -j ACCEPT
    iptables -D INPUT -i $IFACE -j DROP
fi

cat $RUN_DIR/ip_fwd.$$ > /proc/sys/net/ipv4/ip_forward
mv  $RUN_DIR/ip_fwd.$$ $RUN_DIR/ip_fwd.old

ifconfig $IFACE 0.0.0.0
ifconfig $IFACE down
