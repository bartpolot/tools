#!/bin/bash

# SHARES="AAPL,GOOG"

if [[ "$1" != "full" && "$1" != "" && "$1" != "v" ]]; then
    SHARES=$1
fi


# Format info: http://code.google.com/p/yahoo-finance-managed/wiki/enumQuoteProperty
FORMAT=""
FORMAT="${FORMAT}s"    # Symbol
FORMAT="${FORMAT}l1"   # Last trade
FORMAT="${FORMAT}c1"   # Change O -> LT
FORMAT="${FORMAT}p2"   # Chanhe O -> LT (%)
FORMAT="${FORMAT}d1"   # Date LT
FORMAT="${FORMAT}t1"   # Time LT
FORMAT="${FORMAT}p"    # Previous close
FORMAT="${FORMAT}o"    # Open
FORMAT="${FORMAT}h"    # Day High
FORMAT="${FORMAT}g"    # Day Low
FORMAT="${FORMAT}v"    # Volume


URL='http://download.finance.yahoo.com/d/quotes.csv?'
URL="${URL}s=${SHARES}&f=${FORMAT}&e.csv"

echo $URL

RET=`timeout 5 curl --connect-timeout 5 -s $URL | tr , ' '`

if [ "$RET" = "" ]; then
    echo "N/A"
fi
# echo "RET: $RET"

if [ "$1" = "full" ]; then
    echo -e "\
 Symbol\
 Current\
   Change\
 Change%\
  |   Close\
    Open\
 Current\
      Min\
       Max\
        Stand\
  Volume\
"
fi


echo "$RET" | while read line; do
    ARRAY1=($line)
    ARRAY=()

    for i in ${ARRAY1[@]}; do
	i=${i//\"/}
	ARRAY+=("`printf "%7s" $i`")
    done
    
    S=${ARRAY[0]}  # Symbol
    LT=${ARRAY[1]} # LastTrade
    C=${ARRAY[2]}  # Change
    CP=${ARRAY[3]} # Change %
    D=${ARRAY[4]}  # Day
    T=${ARRAY[5]}  # Time
    P=${ARRAY[6]}  # Previous close
    O=${ARRAY[7]}  # Open
    DH=${ARRAY[8]} # DayHigh
    DL=${ARRAY[9]} # DayLow
    V=${ARRAY[10]} # Volume

    D=`date -d '7/3/2013' +'%d/%'m`
    T=`date -d "TZ=\"America/New_York\" $T" +'%R'`
    if [ "$1" = "full" ]; then
	echo -e "$S $LT ($C $CP) | $P $O $LT ($DL - $DH) $D $T $V"
    elif  [ "$1" = "" ]; then
	echo -ne "\${color1}${S%%.*} \$color$CP | "
    elif  [ "$1" = "v" ]; then
	echo -ne "${S%%.*} $CP "
    else
	if [ "$2" = "" ]; then
	    echo -ne "$CP"
	else
	    eval echo -ne "\$$2"
	fi
    fi
done
