#!/bin/sh

TMPFILE=`mktemp`
TMPERR=`mktemp`

if [ $# -gt 0 ]; then
    IF=$1
else
    >&2 echo No interface provided, using \"wlan0\"
    IF=wlan0
fi

iw dev $IF link 2>$TMPERR > $TMPFILE
if [ $? != 0 ]; then
    >&2 echo Problem with interface $IF: `cat $TMPERR`
    rm $TMPFILE $TMPERR
    exit 1
fi
grep SSID $TMPFILE | sed -e 's/.*SSID: //'
rm $TMPFILE $TMPERR
