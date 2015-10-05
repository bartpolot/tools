#!/bin/bash

N=`pacman -Qqu | wc -l`

for p in `pacman -Qque`; do
    LINE=$LINE${LINE+ / }$p
done

if [ $N -eq 0 ]; then
    echo "Up to date!"
    exit 0
fi

export XDG_RUNTIME_DIR=/run/user/$UID
export DISPLAY=:0
kdialog --title "Pacman: $N updates, most important:" --passivepopup "$LINE" 10
