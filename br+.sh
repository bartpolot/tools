#!/bin/bash

SYSFILE=/sys/class/backlight/intel_backlight/brightness
GOAL_FILE="$XDG_RUNTIME_DIR/brightness/goal"


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
}


################################################################

mkdir -p `dirname $GOAL_FILE` || exit 1

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


# Kill other instances just in case
for i in `pgrep 'br[+|-].sh'`; do
    if [ $i != $$ ]; then
	echo Other: $i
	kill $i
    fi
done

################################################################

MAX_BR=`cat /sys/class/backlight/intel_backlight/max_brightness`
CURR_BR=`cat /sys/class/backlight/intel_backlight/brightness`

echo "" >> /tmp/br
date >> /tmp/br
echo "We are now at $CURR_BR of $MAX_BR" >> /tmp/br

# Set goal
NEW=$((CURR_GOAL+STEP*5))
get_lvl
LAG=$((CURR_GOAL-LEVEL))
if [ $LAG != 0 ]; then
    NEW=$((NEW+STEP*10))
    echo "LAG! Step it up!"
fi
if [ $NEW -gt 100 ]; then
    NEW=100
elif [ $NEW -lt 0 ]; then
    NEW=0
fi
echo $NEW > $GOAL_FILE


[ $NEW -ge 100 ] && NEW_BR=$MAX_BR || get_br $NEW


DELTA=$((NEW_BR-CURR_BR))
[ $DELTA = 0 ] && exit 0
STEP_BR=$((DELTA/8))
[ $STEP_BR = 0 ] && STEP_BR=$STEP


echo "We are at $LEVEL, goal is $NEW (was $CURR_GOAL), LAG: $LAG" >> /tmp/br
echo "Delta is $DELTA" >> /tmp/br
echo "Step is $STEP_BR" >> /tmp/br
echo "$((CURR_BR+STEP_BR)) $STEP_BR $NEW_BR" >> /tmp/br
#DELTA=`echo "scale=0; sqrt($BR)" | bc -l`

for i in `seq $((CURR_BR+STEP_BR)) $STEP_BR $NEW_BR`; do
    echo $i | sudo tee $SYSFILE
done
echo $NEW_BR | sudo tee $SYSFILE

echo "" >> /tmp/br


exit 0
sleep 60
