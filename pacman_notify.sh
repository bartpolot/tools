#!/bin/sh

N=`pacman_count_updates`

if [ $N -eq 0 ]; then
    echo "Up to date!"
    exit 0
fi

for p in `pacman -Que | grep -v '\[ignored\]' | cut -d' ' -f 1`; do
    LINE=$LINE${LINE+ / }$p
done


export XDG_RUNTIME_DIR=/run/user/$UID
export DISPLAY=:0
kdialog --title "Pacman: $N updates, most important:" --passivepopup "$LINE" 10
