#!/bin/bash
# COLORIZE_STR := ="SUBSSTITUTION (|SUBSTITUTION)*"
# SUBSTITUTION := WHAT COLOR HOW"
# WHAT         := Any string
# COLOR        := escape sequence for a color, for instace "\033[1;32m"
# HOW          := w|l (w: word, colorize just WHAT, l: line, colorize whole line containing WHAT)
#
# EXAMPLE:
#export COLORIZE_STR="\
#CADET ... AAAA \033[1;32m l|\
#CADET ... BBBB \033[1;31m l|\
#CADET ... CCCC \033[1;34m l|\
#CADET ... DDDD \033[1;33m w|\
#CADET ... EEEE \033[1;37m l"

IFS="|" read -r -a COLOR_A <<< $COLORIZE_STR
RST=`printf $txtrst`

REGEX=""
for i in "${COLOR_A[@]}"; do
    IFS=" " read -r -a LINE_A <<< $i
    J=${#LINE_A[@]}
    J=$((J-1))
    HOW=${LINE_A[$J]}
    J=$((J-1))
    COLOR_STR=${LINE_A[$J]}
    COLOR=`echo -e $COLOR_STR`
    WHAT=${LINE_A[@]:0:$J}

    if [ "$HOW" = "l" ]; then
	REGEX="${REGEX}s/(.*$WHAT.*)/$COLOR\1$RST/;"
    else
	REGEX="${REGEX}s/($WHAT)/$COLOR\1$RST/;"
    fi
done

sed -re "$REGEX" $@
