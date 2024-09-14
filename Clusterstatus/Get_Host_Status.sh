#!/bin/bash
base=$1
beg=$2
end=$3
ALL_HOSTS=$4
DOWN_HOSTS=$5
UP_HOSTS=$6

# -------------------- get_host ---------------------------

get_host ()
{
base=$1
ipnum=$2
if [ $ipnum -gt 99 ]; then
  host=$base$ipnum
else
  if [ $ipnum -gt 9 ]; then
    host=${base}0$ipnum
  else
    host=${base}00$ipnum
  fi
fi
echo $host
}

#define host arrays

rm -rf $ALL_HOSTS
for i in `seq $beg  $end`; do
  HOST=`get_host $base $i`
  echo $HOST >> $ALL_HOSTS
done

pbsnodes -l | awk '{print $1}' | sort -u  > $DOWN_HOSTS

nlines_down=0
if [ -e $DOWN_HOSTS ]; then
  nlines_down=`cat $DOWN_HOSTS | wc -l`
fi

if [ $nlines_down -eq 0 ]; then
  cp $ALL_HOSTS $UP_HOSTS
else
  grep -v -x -f $DOWN_HOSTS $ALL_HOSTS > $UP_HOSTS
fi

#define array of hosts that are up

export UP_HOST_LIST=
for HOST in `cat $UP_HOSTS`; do
  if [ "$UP_HOST_LIST" == "" ]; then
    UP_HOST_LIST="$HOST"
  else
    UP_HOST_LIST="$UP_HOST_LIST,$HOST"
  fi
done
