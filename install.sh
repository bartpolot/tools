#!/bin/bash

TARGET=${1:-$HOME/bin}

for i in *.sh; do
    if [ "$i" = "$0" ]; then
	continue
    fi
    cp "$i" "$TARGET/${i%%.sh}"
done
