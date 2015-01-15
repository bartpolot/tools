#!/bin/sh

echo "$@" > /tmp/testme

DISPLAY=:0

ME=`basename $0`

REMOTE=$HOME/remote
AUTO_DIR=.auto_torrent

TARGET=$REMOTE/$AUTO_DIR


if [ ! -w "$TARGET" ]; then
    mount $REMOTE
    if [ ! -w "$TARGET" ]; then
	kdialog --error "Cant access remote" --title "Torrent"
	exit 1
    fi
fi

T=$1

case $T in
    magnet*)
	N=`echo $T | sed -e 's/.*&dn=\([^&]*\).*/\1/'`	     
	kdialog --title "Dowloading Magnet" --passivepopup "$N" 5
	F="$N.magnet"
	echo $T > "$TARGET/$F"
	;;
    *.torrent)
	N=${T##*/}
	N=${N%.torrent}
	N=${N%.*}
	F=`basename "$T"`
	umask 000
	chmod a+rw "$T"
	cp "$T" "$TARGET/$F"
	;;
esac

kdialog --title "$ME" --passivepopup "Starting download:
$N..." 5

rm "$TARGET/$F.invalid"
while true; do
    ls "$TARGET" > /dev/null
    if [ -f "$TARGET/$F.invalid" ]; then
	kdialog \
	    --title "$ME" \
	    --passivepopup "Error downloading:
 $N
Try again or call a kat." \
	    15
	rm "$TARGET/$F.invalid"
	exit 1
    fi
    if [ ! -f "$TARGET/$F" ]; then
	break
    fi
    sleep 0.5;
done

kdialog --title "$ME" --passivepopup "$N started!" 5
