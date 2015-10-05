#!/bin/bash
tail -n 1000  /var/log/bat > /tmp/bat_last.dat
gnuplot -e 'set xdata time; set timefmt "%Y-%m-%d %H:%M:%S"; set xlabel "Time"; set ylabel "%"; plot "/tmp/bat_last.dat" using 2:4 with linespoints ti "level"' -p;
#gnuplot -e 'set xdata time; set timefmt "%Y-%m-%d %H:%M:%S"; set xlabel "Time"; set ylabel "mWh"; plot "/tmp/bat_last.dat" using 2:5 with linespoints ti "level"' -p
gnuplot -e 'set xdata time; set timefmt "%Y-%m-%d %H:%M:%S"; set xlabel "Time"; set ylabel "mW"; plot  "/tmp/bat_last.dat" using 2:7 with linespoints ti "usage", "/tmp/bat_last.dat" using 2:6 with lines ti "avg"; ' -p
