#!/bin/bash

# where to install, if not provided as the first argument
TARGET=${1:-$HOME/bin}

# regexp for excludes
EXCLUDE="^install.sh$ ^meta-update.sh$"

for i in *.sh; do
    skip="";
    for j in $EXCLUDE; do
	if [[ $i =~ $j ]]; then
	    skip="yes"
	    break
	fi
    done
    if [[ $skip ]]; then
	continue
    fi

    cp "$i" "$TARGET/${i%%.sh}"
done
