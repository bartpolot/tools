#!/bin/sh
IFS=+;
lang=en;
Q_ORIG=`xclip -o`;
Q="${Q_ORIG// /%20}";
curl -s "https://dict.leo.org/${lang}de/?search=$Q" > .html
     html2text -b 150 .html | \
     iconv -t UTF8//IGNORE 2>/dev/null | \
     grep -EA 900 '^\*{5} ' | \
     grep -EB 900 '^\*{4} Weitere Aktionen' | \
     head -n -1 > .__lx;
H=`cat .__lx | wc -l`;
W=`cat .__lx | wc -L`;
kdialog --textbox .__lx $((W * 6 + 50)) $((H * 13 + 100)) --title "$Q_ORIG ($W x $H)";
rm .__lx;
