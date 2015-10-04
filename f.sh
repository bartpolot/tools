#!/bin/sh

if [ "$#" -lt 3 ]; then
    echo "usage: $0 FILE FROM TO"
    exit 1;
fi   

FILE=$1
FROM=$2
TO=$3


grep "$FROM" $FILE -A 1000000 -B 1000 | grep "$TO" -B 1000000 -A 1000
