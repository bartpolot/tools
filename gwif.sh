#!/bin/sh
ip route list 0/0 | sort -k 9 | head -n 1 | cut -f 5 -d' '
