#!/bin/bash

SYS_FILE=/sys/class/backlight/intel_backlight/brightness
GOAL_FILE=/tmp/brightness/goal

echo ------------------------------------- >> /tmp/br+
#/usr/bin/sudo date >> /tmp/br+
#sudo true >> /tmp/br+
whoami >> /tmp/br+
date "+%H:%M:%S.%N" >> /tmp/br+

# only one instance
BASENAME=`basename $0`
PIDS=`pgrep -x $BASENAME`
for pid in $PIDS; do
    if [ "$$" -lt $pid ]; then
	exit 0
    elif [ "$$" -gt $pid ]; then
	kill $pid
    fi
done


# Get new brightness
function get_br ()
{
    L=$1
    if [ $L = 100 ]; then
	NEW_BR=$MAX_BR
    elif [ $L = 0 ]; then
	NEW_BR=0
    else
	NEW_BR=`echo "scale=10; $MAX_BR*($L/100)^2+1" | bc`
    fi
    NEW_BR=${NEW_BR%%.*}
}

# Get current level
function get_lvl ()
{
    if [ $CURR_BR = $MAX_BR ]; then
	LEVEL=100
    elif [ $CURR_BR = 0 ]; then
	LEVEL=0
    else
	LEVEL=`echo "scale=10; 100*sqrt($CURR_BR/$MAX_BR)" | bc`
    fi
    LEVEL=${LEVEL%%.*}
    echo "$CURR_BR / $MAX_BR = $LEVEL" >> /tmp/br+
}


################################################################

GOAL_DIR=`dirname $GOAL_FILE`
mkdir -p $GOAL_DIR || exit 1
chmod a+rX $GOAL_DIR


# Set goal
if [ -f $GOAL_FILE ]; then
    CURR_GOAL=`cat $GOAL_FILE`
else
    CURR_GOAL=$((100*CURR_BR/MAX_BR))
fi


# Figure out step
echo $0 | grep '+' > /dev/null
if [ $? = 0 ]; then
    [ $CURR_GOAL = 100 ] && exit 0;
    STEP=1
else
    [ $CURR_GOAL = 0 ] && exit 0;
    STEP=-1
fi


################################################################

MAX_BR=`cat /sys/class/backlight/intel_backlight/max_brightness`
CURR_BR=`cat /sys/class/backlight/intel_backlight/actual_brightness`

echo $$ CURR $CURR_BR >> /tmp/br+

# Set goal
NEW=$((CURR_GOAL+STEP*5))
get_lvl
LAG=$((CURR_GOAL-LEVEL))
if [ $LAG -gt 1 ]; then
    NEW=$((NEW+STEP*10))
fi
if [ $NEW -gt 100 ]; then
    NEW=100
elif [ $NEW -lt 0 ]; then
    NEW=0
fi
echo $NEW > $GOAL_FILE
echo "$LEVEL > $NEW ($LAG)" >> /tmp/br+ 

[ $NEW -ge 100 ] && NEW_BR=$MAX_BR || get_br $NEW

DELTA=$((NEW_BR-CURR_BR))
[ $DELTA = 0 ] && exit 0
STEP_BR=$((DELTA/10))
[ $STEP_BR = 0 ] && STEP_BR=$STEP


for i in `seq $((CURR_BR+STEP_BR)) $STEP_BR $NEW_BR`; do
    echo $i | sudo tee $SYS_FILE
    echo $$ $i >> /tmp/br+
done
echo $NEW_BR | sudo tee $SYS_FILE >> /tmp/br+

date "+%H:%M:%S.%N" >> /tmp/br+
