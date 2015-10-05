#!/bin/bash

SYS_FILE=/sys/class/backlight/intel_backlight/brightness
LOCK_DIR=/tmp/br_show/

if ! mkdir $LOCK_DIR; then
    exit 0
fi

sleep 0.15;
while pgrep "br[+|-]"; do
    sleep 0.005;
done

L=`cat $SYS_FILE`
dbus-send \
    --print-reply \
    --dest=org.kde.Solid.PowerManagement \
    /org/kde/Solid/PowerManagement/Actions/BrightnessControl \
    org.kde.Solid.PowerManagement.Actions.BrightnessControl.setBrightness \
    int32:$L

rmdir $LOCK_DIR
