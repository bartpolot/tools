#!/bin/bash
F1=`mktemp`
F2=`mktemp`
A=`curl -s https://api.kraken.com/0/public/Depth?pair=XBTEUR`;
echo $A | jq '.result.XXBTZEUR.bids | map (.[0])[]' | head > $F1
echo $A | jq '.result.XXBTZEUR.asks | map (.[0])[]' | head > $F2;
paste $F2 $F1
rm $F1 $F2
