#!/bin/sh
ps axo %a | grep [g]nunet | cut -f 1 -d ' ' | sort | uniq -c
