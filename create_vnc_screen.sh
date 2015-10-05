#!/bin/sh

export DISPLAY=:0
xrandr --newmode                 1440x900_30.00  49.25  1440 1480 1616 1792  900 903 909 919 -hsync +vsync
xrandr --addmode VIRTUAL1        1440x900_30.00
xrandr --output  VIRTUAL1 --mode 1440x900_30.00 --panning 1440x900+1920+0
x11vnc -clip 1440x900+1920+0 -many
