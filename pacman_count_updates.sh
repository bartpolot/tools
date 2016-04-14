#!/bin/sh

echo "`pacman -Qu $1 | grep -v '\[ignored\]' | wc -l`"
