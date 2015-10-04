#!/bin/bash
cat /var/log/bat | cut -d' ' -f 2 | uniq > days
for i in `cat days`; do
    echo -n "$i " >> data.dat;
    grep ' -' /var/log/bat | grep $i | cut -d' ' -f 6 | bin/avg >> data.dat;
    echo $i;
done
gnuplot -e 'set xdata time; set timefmt "%Y-%m-%d"; plot "data.dat" using 1:2 with lines' -p
