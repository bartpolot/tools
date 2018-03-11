#!/bin/sh

echo "$@" > /tmp/testme

## READ config file
#
# EXAMPLE:
# export remote_dir=$HOME/my_nfs_path
# export auto_dir=.auto_torrent
# export display=:0
source $HOME/.config/TorrentMagic.rc

# Set variables
me=`basename $0`
DISPLAY=${display:-:0}
remote=${remote_dir:-"$HOME/remote"}
auto_dir=${auto_dir:-".auto_torrent"}
target=$remote/$auto_dir

# Make sure the taget directory is available and mounted
if [ ! -w "$target" ]; then
    mount $remote
    if [ ! -w "$target" ]; then
	kdialog --error "Cant access remote \"$target\"" --title "Torrent"
	exit 1
    fi
fi

T=$1

case $T in
    magnet*)
	N=`echo $T | sed -e 's/.*&dn=\([^&]*\).*/\1/'`	     
	kdialog --title "Dowloading Magnet" --passivepopup "$N" 5
	F="$N.magnet"
	echo $T > "$target/$F"
	;;
    *.torrent)
	N=${T##*/}
	N=${N%.torrent}
	N=${N%.*}
	F=`basename "$T"`
	umask 000
	chmod a+rw "$T"
	cp "$T" "$target/$F"
	;;
esac

kdialog --title "$me" --passivepopup "Starting download:
$N..." 5

rm "$target/$F.invalid"
while true; do
    ls "$target" > /dev/null
    if [ -f "$target/$F.invalid" ]; then
	kdialog \
	    --title "$me" \
	    --passivepopup "Error downloading:
 $N
Try again or call a kat." \
	    15
	rm "$target/$F.invalid"
	exit 1
    fi
    if [ ! -f "$target/$F" ]; then
	break
    fi
    sleep 0.5;
done

kdialog --title "$me" --passivepopup "$N started!" 5
