#!/bin/sh

if [ $# -lt 1 ]; then
    echo usage: $0 [WHAT TO HIGHLIGHT]
    exit 1
fi

case $1 in
    IP)
	REGEX="([0-9.]+\.){3}[0-9]+"
	;;
    *)
	REGEX="$1"
	;;    
esac


export COLORIZE_STR="$REGEX \033[1;32m w|"
colorize
