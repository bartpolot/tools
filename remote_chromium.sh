#!/bin/bash

function start_remote {
    f=$1
    H=${f##*-}
    CFGDIR=`ls -1d *-$H`
    PORT=$((RANDOM % 15000 + 5000))
    echo $H
    
    ssh -ND $PORT $H &
    SSHPID=$!
    
    kdialog --title "Chromium at..." --passivepopup "$H" 2
    sleep 1
    chromium \
	--high-dpi-support=1 \
	--force-device-scale-factor=1 \
	--proxy-server="socks5://localhost:$PORT" \
	--user-data-dir=$CFGDIR \
	-disable-prompt-on-repost
    
    kill $SSHPID
}


cd ~/.config/.remotes/


if [ "$1" != "" ]; then
    start_remote $1
else
    for f in *; do
	start_remote $f
    done
fi


kdialog --title "Remote chromium" --passivepopup "Done!" 2
