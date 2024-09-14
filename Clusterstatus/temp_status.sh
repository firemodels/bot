#!/bin/bash

# ---------------------------- get_temp ----------------------------------
get_temp()
{
  if [ "$TEMP_IP" != "" ]; then
    CURDIR=`pwd`
    cd $logdir
    rm -f temp
    wget -o test.out $TEMP_IP
    temp=`cat temp| awk -F'|' '{print $(2)'}`
    rm -f test.out temp
    cd $CURDIR
  fi
}

# ---------------------------- WARN_TEMP ----------------------------------
WARN_TEMP ()
{
  local temp_high=$1
  local temphigh_lock=$logdir/$2
  if [ ! -e $temphigh_lock ]; then
    if (( $(echo "$temp > $temp_high" |bc -l) )); then
      touch $temphigh_lock
      echo "***warning cluster room temp: $temp"
      echo "" | Mail -s "***warning cluster room temp: $temp" gforney@gmail.com
      exit
    fi
  fi
}

# ---------------------------- WARN_ALL_TEMP ----------------------------------
WARN_ALL_TEMP ()
{
  local temp_high=$1
  local temphigh_lock=$logdir/$2
  if [ ! -e $temphigh_lock ]; then
    if (( $(echo "$temp > $temp_high" |bc -l) )); then
      touch $temphigh_lock
      echo "***warning cluster room temp: $temp"
      echo "" | Mail -s "***warning cluster room temp: $temp" gforney@gmail.com randy.mcdermott@gmail.com
      exit
    fi
  fi
}

# ---------------------------- usage ----------------------------------
function usage {
  echo " -h - show this message"
  echo " -d - test - email current temperature"
  exit
}

DAILY=
TEMP_IP=129.6.159.193/temp
CLEAR_LOGS=

while getopts 'hdr' OPTION
do
case $OPTION in
  h)
  usage
  ;;
  d)
  DAILY=1
  ;;
  r)
  CLEAR_LOCKS=1
  ;;
esac
done
shift $(($OPTIND-1))

logdir=$HOME/.temp_status
host=`hostname -s`
if [ ! -d $logdir ]; then
  mkdir $logdir
  touch $logdir/temp_$host.csv
fi

if [ "$CLEAR_LOCKS" != "" ]; then
  rm -f $logdir/*lock*
fi

get_temp
if [ "$DAILY" != "" ]; then
  echo temperature: $temp
  echo "`date`" | Mail -s "cluster room temp: $temp" gforney@gmail.com
  exit
fi
WARN_ALL_TEMP 55.0 lock85
WARN_ALL_TEMP 90.0 lock90
WARN_TEMP     75.0 lock75
WARN_TEMP     80.0 lock80
