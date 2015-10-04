#!/bin/sh

TESTBED_DIR=`ls /tmp/testbed*/2/ -d`
TESTBED_SUFFIX=${TESTBED_DIR##*testbed}
TESTBED_SUFFIX=${TESTBED_SUFFIX%%/*}

echo -n "Using /tmp/testbed$TESTBED_SUFFIX/";
COUNT_PEERS=`ls -1d /tmp/testbed$TESTBED_SUFFIX/* | wc -l`
echo " with $COUNT_PEERS peers";

for i in /tmp/testbed$TESTBED_SUFFIX/*; do 
    gnunet-statistics -c $i/config -s dht | grep "peers "; 
done > conns
echo "`cat conns | wc -l` peers are connected"
cat conns | tr -s  ' ' | cut -d ' ' -f 6 > conns2
paste -sd+ conns2 | bc
rm conns
rm conns2
