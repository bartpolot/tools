#!/bin/bash

LIST=`pacman -Qqu`
ACT=` wc -w <<< $LIST`
LIST=`echo $LIST`

if [ $ACT -eq 0 ]; then
    echo "Up to date!"
    exit 0
fi

export XDG_RUNTIME_DIR=/run/user/$UID
export DISPLAY=:0
kdialog --title "Pacman: $ACT updates" --passivepopup "$LIST" 10
