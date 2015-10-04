#!/bin/bash

function error ()
{
    if [ $E = "kde" ]; then
	kdialog --error "$1"
    else
	echo -ne "\e[1;31m"
	echo -n "$1"
	echo -e "\e[0m"
    fi    
}


function info ()
{
    if [ $E = "kde" ]; then
	echo "title: $2"
	echo "message: $1"
	kdialog ${2:+--title "$2"} --passivepopup "$1" 5
    else
	echo -ne "\e[0;34m"
	echo -n "$1"
	echo -e "\e[0m"
    fi    
}


function progress ()
{
    if [ $E = "kde" ]; then
	TEXT="Downloading $3"
	qdbus $dbusRef Set "" "value" $1;
	qdbus $dbusRef setLabelText "$TEXT"
    else
	TEXT="Downloading (image $1/$2): $3"
	echo -ne "\e[1;37m"
	echo -ne $TEXT
	echo -e "\e[0m"
    fi    
}

function cleanup_and_exit ()

{
    rm /tmp/.ww_html_$T
    rm /tmp/.ww_list_$T
    
    FAIL=`file $DIR/* | grep HTML | cut -d':' -f 1 | wc -l`
    file $DIR/* | grep HTML | cut -d':' -f 1 | xargs rm

    info "Wallpapers downloaded,
$FAIL failed ($RES not available)" "Download $T finished"

    exit 0
}




ps -h -ocomm -p $PPID | grep ".*sh" > /dev/null
if [ $? = 0 ]; then
    E="cli"
else
    E="kde"
fi

RES=`DISPLAY=:0 xrandr | grep 'current' | sed -e 's/.*current \([0-9]\+\) x \([0-9]\+\).*/\1x\2/'`

URL=`DISPLAY=:0 xclip -o`

echo "$URL" | grep '^http://wallpaperswide.com/' > /dev/null
if [ $? != 0 ]; then
    error "\"$URL\" is not a valid wallpaperswide URL"
    exit 1
fi

THEME=`echo $URL | sed -e 's|.*\.com/\([a-zA-Z_-]\+\).*|\1|'`
THEME=${THEME%%/page/*}
T=${THEME%%-desktop-wallpapers}
DIR="$HOME/img/wallpapers/$T-$RES"
mkdir -p "$DIR"

wget http://wallpaperswide.com/$THEME -O /tmp/.ww_html_$T -q
PAGES=`grep 'page/[0-9]*' /tmp/.ww_html_$T -o | tail -2 | head -1`
PAGES=${PAGES##page/}

i=0

grep 'http.*jpg' /tmp/.ww_html_$T -o | sed -e "s/thumbs/download/;s/t1/wallpaper-$RES/;s/hd\.//" > /tmp/.ww_list_$T
PER_PAGE=`cat /tmp/.ww_list_$T | wc -l`
IMGS=$((PAGES*PER_PAGE))


MSG="Using resolution $RES
URL: $URL
Theme $T has $PAGES pages of $PER_PAGE elements"

echo "$MSG"

if [ "$E" = "kde" ]; then
    dbusRef=`kdialog --progressbar "Dowloading $IMGS images" $IMGS \
             --geometry 500x100 --title "Dowloading $IMGS \"$T\" wallpapers"`
    qdbus $dbusRef showCancelButton true
fi

for i in `seq 1 $PAGES`; do

    wget http://wallpaperswide.com/$THEME/page/$i -O /tmp/.ww_html_$T -q
    grep 'http.*jpg' /tmp/.ww_html_$T -o | sed -e "s/thumbs/download/;s/t1/wallpaper-$RES/;s/hd\.//" > /tmp/.ww_list_$T

    j=0
    for f in `cat /tmp/.ww_list_$T`; do
	j=$((j+1))
	NAME=`echo $f | sed -e "s|.*download/\([a-zA-Z0-9_-]\+\)-$RES.jpg|\1|"`
	N=${NAME%%-wallpaper}
	
	progress $(((i-1)*PER_PAGE+j)) $IMGS $N

	EXT=${f##*.}
	FILENAME="$DIR/$N.$EXT"
	if [ -f "$FILENAME" ]; then
	    echo "$N exists" "Wallpaper download \"$T\""
	else
	    wget -q $f --referer http://wallpaperswide.com/${NAME}s.html -O "$FILENAME"
	fi
	if [ "$E" = "kde" ]; then
	    RESP=`qdbus $dbusRef wasCancelled`
	    EXIT_CODE=$?
	    if [ "false" != "$RESP" -o "$EXIT_CODE" != 0 ]; then
		qdbus $dbusRef close > /dev/null
		cleanup_and_exit
	    fi
	fi

    done
    echo ""

done

if [ "$E" = "kde" ]; then
    qdbus $dbusRef close;
fi

cleanup_and_exit
