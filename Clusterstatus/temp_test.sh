#!/bin/bash
test=$1
logdir=$HOME/.cluster_status
load=`tail -1 ~/.cluster_status/load_blaze.csv | awk -F',' '{print $2}'`
temp=`tail -1 ~/.cluster_status/load_blaze.csv | awk -F',' '{print $3}'`
tempcrit1=85.0
temphi1=temphi1
tempcrit2=90.0
temphi2=temphi2
MAILLIST="gforney@gmail.com randy.mcdermott@gmail.com"

if [ -e $temphi1 ]; then
  if (( $(echo "$temp < $tempcrit1" |bc -l) )); then
    rm $temphi1
    echo "" | Mail -s "***fyi temp: $temp, now below $tempcrit1" $MAILLIST
  fi
else
  if (( $(echo "$temp > $tempcrit1" |bc -l) )); then
    touch $temphi1
    echo "" | Mail -s "***warning temp: $temp>$tempcrit1" $MAILLIST
  fi
fi

if [ -e $temphi2 ]; then
  if (( $(echo "$temp < $tempcrit2" |bc -l) )); then
    rm $temphi2
    echo "" | Mail -s "***fyi temp: $temp, now below $tempcrit2" $MAILLIST
  fi
else
  if (( $(echo "$temp > $tempcrit2" |bc -l) )); then
    touch $temphi2
    echo "" | Mail -s "***warning temp: $temp>$tempcrit2" $MAILLIST
  fi
fi

if [ "$test" == "test" ]; then
  echo "" | Mail -s "load: $load, temp: $temp" $MAILLIST
fi
