#!/bin/sh
#/sys/class/backlight/intel_backlight/brightness

for i in `pgrep 'br[+|-].sh'`; do
    echo $i
    if [ $i != $$ ]; then
	kill $i
    fi
done

BR=`qdbus org.freedesktop.PowerManagement /org/kde/Solid/PowerManagement/Actions/BrightnessControl brightness`

DELTA=`echo "scale=0; sqrt($BR)" | bc -l`
if [ $DELTA -lt 2 ]; then
    DELTA=2
fi

echo $0 | grep '+'
if [ $? = 0 ]; then
    NEW=$((BR+DELTA))
    STEP=1
else
    NEW=$((BR-DELTA))
    STEP=-1
fi


if [ $NEW -gt 100 ]; then
    NEW=100
fi
if [ $NEW -lt 0 ]; then
    NEW=0
fi


for i in `seq $BR $STEP $NEW`; do
    qdbus \
	org.freedesktop.PowerManagement \
	/org/kde/Solid/PowerManagement/Actions/BrightnessControl \
	setBrightness $i;
    sleep 0.05
done


sleep 60
