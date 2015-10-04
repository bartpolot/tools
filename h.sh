#!/bin/sh

if [ "$#" -lt 1 ]; then
    echo "usage: $0 FILE"
    exit 1;
fi   

FILE=$1

if ! grep -q 'ERROR.*service' $FILE; then
    echo "No errors";
    exit
fi
L=`grep -n 'ERROR.*service' $FILE | head -n 1 | cut -d':' -f 1`

echo $L
read

head -n $((L+50)) $FILE | tail -n 10000 | colorize | tee .h | less -RS
