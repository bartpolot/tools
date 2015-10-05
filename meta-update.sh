#!/bin/bash

# regexp for excludes
EXCLUDE="^README$ ^.gitignore$ ^Makefile .conf$ ^meta-update.sh$"

for i in `git ls-files`; do
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
    if ! grep -q "^${i%.*}\$" README; then
	echo "not documented: $i"
    fi
done
