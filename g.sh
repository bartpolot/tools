#!/bin/sh

if [ "$#" -lt 3 ]; then
    echo "usage: $0 WHERE WHAT WHICH"
    exit 1;
fi   

WHERE=$1
WHAT=$2
WHICH=$3

if [ -n "$4" ]; then 
    CTX="-C $4"
elif [ -n "$G_CTX" ]; then
    CTX="-C $G_CTX"
else
    CTX="-C 5"
fi

grep $CTX "`grep $WHAT $WHERE | head -n $WHICH | tail -n 1`" $WHERE
