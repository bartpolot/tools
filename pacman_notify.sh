#!/bin/sh

PATH="`dirname $0`:$PATH"
XDG_RUNTIME_DIR=/run/user/$UID
DISPLAY=:0

N=`pacman_count_updates`

if [ $N -eq 0 ]; then
    echo "`date` - Up to date!"
    exit 0
fi

for p in `pacman -Que | grep -v '\[ignored\]' | cut -d' ' -f 1`; do
    LINE=$LINE${LINE+ / }$p
done

kdialog --title "Pacman: $N updates, most important:" --passivepopup "$LINE" 10
