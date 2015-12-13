#!/bin/sh

MUTED=0

mkdir -p /tmp/rmf

cleanup ()
{
    echo > /tmp/rmf/artist
    echo > /tmp/rmf/song
    echo `date` Stop >> /tmp/rmf/log
}

shutdown ()
{
    exit
}


trap cleanup 0


URL=`curl --silent http://www.rmfon.pl/js/rmf.pls | sed -e 's/.*\(http[^"]*\).*/\1/'`

if [ -z $URL ]; then
    echo "No URL in downloaded playlist"
    exit 1
fi

echo `date` Start $URL >> /tmp/rmf/log

mpg123 --output pulse $URL |&
while true; do
    read i;
    D=`date`
    if echo $i | grep ICY-META > /dev/null; then
	A=`echo $i | sed -e "s/.*StreamTitle='\(.*\) - .*/\1/"`
	S=`echo $i | sed -e "s/.*StreamTitle='.* - \(.*\)';S.*/\1/"`
	echo $D: $A - $S | tee -a /tmp/rmf/log
	echo $A > /tmp/rmf/artist
	echo $S > /tmp/rmf/song
	#kdialog --title "RMF" --passivepopup "$A - $S"

	if [ "$MUTED" = 0 ]; then
	    if [ "$S" = "RMF FM" ]; then
		MUTED=1
		L=`pactl list sink-inputs | grep -B 100 mpg123 | grep -e ^Sink | tail -n 1`
		SINK_ID=${L#*#}
		VOL=`pactl list sink-inputs | grep -B 100 mpg123 | grep -e Volume | tail -n 1 | sed -e 's/.* \([0-9]\+\)%.*/\1/'`
		pactl set-sink-input-volume "$SINK_ID" "$((VOL/4))%"
	    fi
	else
	    if [ "$S" != "RMF FM" ]; then
		MUTED=0
		pactl set-sink-input-volume "$SINK_ID" "$VOL%"
	    fi
	fi
	
    fi;
done 
