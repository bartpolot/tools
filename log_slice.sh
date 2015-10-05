#/bin/bash

. /home/bart/.bashrc

TMPFILE=`mktemp`
echo $TMPFILE

xclip -o > $TMPFILE

START=`head -n 1 $TMPFILE | cut -d' ' -f 1-3`
END=`tail -n 1 $TMPFILE | cut -d' ' -f 1-3`
echo $START
echo $END

kdialog --title "Showme" --passivepopup "from: $START \nto:     $END" 1

f /home/bart/g/src/cadet/.log "$START" "$END" | colorize > $TMPFILE

A=""

LINES=`cat $TMPFILE | wc -l`;

echo "#$LINES#"

if [ "$LINES" -lt "1" ]; then
    sleep 0.4
    kdialog --title "Showme $A" --passivepopup "Error $LINES" 5
else
    kdialog --title "$TMPFILE" --passivepopup "$LINES lines" 5
    konsole --nofork -e "less -RS $TMPFILE"
fi

rm $TMPFILE
