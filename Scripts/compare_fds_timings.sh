#!/bin/bash

filelist=/tmp/fds_times$$.txt

CURDIR=`pwd`
fdsrepo=../../fds
cd $fdsrepo
fdsrepo=`pwd`
cd $CURDIR

CURDIR=`pwd`
figrepo=../../fig
cd $figrepo
figrepo=`pwd`
cd $CURDIR

before=$figrepo/compare/firebot/times/base_times.csv
after=`ls -rtlm ~firebot/.firebot/history/*timing*csv | grep -v bench | tail -1 | awk -F',' '{print $1}'`

botrepo=../../bot
cd $botrepo
botrepo=`pwd`
cd $CURDIR

cat $before | head -n -2 | awk -F ',' '{if (NR!=1)  {print($1) }}' > $filelist

files_up=0
files_down=0
time_up=0.0
time_down=0.0
for file in `cat $filelist`; do
  line_before=`grep $file $before`
  line_after=`grep  $file $after`
  if [ "$line_after" == "" ]; then
    continue
  fi
  time_before=`echo $line_before | awk -F',' '{print $2}'`
  time_after=`echo $line_after |   awk -F',' '{print $2}'`
  time_diff=`echo "$time_after - $time_before" | bc`
  got_smaller=$((`echo "$time_before > $time_after"| bc`))
  if [ $got_smaller -eq 1 ]; then
    files_down=$((files_down+1))
    time_down=`echo "$time_down - ($time_diff)" | bc`
  else
    files_up=$((files_up+1))
    time_up=`echo "$time_up + ($time_diff)" | bc`
  fi
done
files_total=`echo "$files_up+$files_down"|bc`
time_total=`echo "$time_up-$time_down"|bc`

echo "smaller,$files_down,$time_down"
echo "bigger,$files_up,$time_up"
echo "total,$files_total,$time_total"

rm $filelist
