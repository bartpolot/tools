#!/bin/bash

ACT=`pacman -Qqu | wc -l`

if [ $ACT -eq 0 ]; then
    echo "Up to date!"
    exit 0
fi

echo "$ACT to update"

if pgrep xshow.sh > /dev/null; then
    echo "Already showing!"
    exit 0
fi

user_name=`whoami`

echo  "Hi $user_name, you have $ACT updates waiting for you.
Please update everypony!" > /tmp/.pony_msg

ponysay -b unicode "`cat /tmp/.pony_msg`" > /tmp/.pony_update

/usr/local/bin/xshow.sh /tmp/.pony_update

#rm /tmp/.pony_msg
#rm /tmp/.pony_update
