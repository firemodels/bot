#!/bin/bash
base=$CB_BASE
beg=$CB_BEG
end=$CB_END

OFFLINE_HOSTS=offline_hosts
DOWN_HOSTS=down_hosts
UP_HOSTS=up_hosts
ALL_HOSTS=all_hosts

# -------------------- get_id ---------------------------

get_id ()
{
ipnum=$1
if [ $ipnum -gt 99 ]; then
  id=$ipnum
else
  if [ $ipnum -gt 9 ]; then
    id=0$ipnum
  else
    id=00$ipnum
  fi
fi
echo $id
}

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

#
ETHOUT=/tmp/eth.$$
ETHOUT=eth
begid=`get_id $beg`
endid=`get_id $end`
CHECK_HOSTS=$base[$begid-$endid]
pdsh -t 1 -w $CHECK_HOSTS date   >& $ETHOUT
DOWN_HOSTS_VAR=`sort $ETHOUT | grep -E 'timed|refused|route' | awk -F':' '{print $1}' | awk '{printf "%s ", $1}'`
rm -f $DOWN_HOSTS
for h in $DOWN_HOSTS_VAR ; do
  echo $h >> $DOWN_HOSTS
done

OFFLINE_HOSTS_TEMP=offline2
OFFLINE_HOSTS_VAR=`pbsnodes -l | awk '{print $1}' | sort -u`
rm -f $OFFLINE_HOSTS_TEMP
for h in $OFFLINE_HOSTS_VAR ; do
  echo $h >> $OFFLINE_HOSTS_TEMP
done
grep -v -x -f $DOWN_HOSTS $OFFLINE_HOSTS_TEMP > $OFFLINE_HOSTS
rm -f $OFFLINE_HOSTS_TEMP

echo down nodes: `cat $DOWN_HOSTS`
echo offline nodes: `cat $OFFLINE_HOSTS`

