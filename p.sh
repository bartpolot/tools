#!/bin/sh

if [ "$#" -lt 2 ]; then
    echo "usage: $0 PEER FILE"
    exit 1;
fi   

L=$1
shift



grep "cadet ... $L$L$L$L" $@
