#!/bin/bash
arg=$1
HOST_BASE=$2
HOST_BEG=$3
HOST_END=$4

# 1.  define the STATUS_WEBPAGE environmental containing the webpage directory for summary results
#     produced by this script
#     example: 
#        export STATUS_WEBPAGE=/var/www/html/summary.html
# 2.  define the STATUS_MAILTO environment variable containing an email
#     address to email results too.
#     example: 
#        export STATUS_MAILTO=user@gmail.com
# 3.  define the STATUS_TEMP_IP variable if you have a temperature sensor
#     (this script will not generate temperature plots if STATUS_TEMP_IP
#     is blank)

# STATUS_MAILTO is defined in .bashrc (so we email addresses in the repo)
if [ "$STATUS_MAILTO" != "" ]; then
  mailTo=$STATUS_MAILTO
fi

daily=
if [ "$arg" == "daily" ]; then
  daily=daily
  arg=gettemp
fi

WARN_TEMP ()
{
  local temp_high=$1
  local temphigh_lock=$logdir/$2
  if [ ! -e $temphigh_lock ]; then
    if (( $(echo "$temp > $temp_high" |bc -l) )); then
      touch $temphigh_lock
      echo "***warning: cluster room temperature is greater than $temp_high" 
      if [ "$mailTo" != "" ]; then
        echo "***warning: cluster room temperature is greater than $temp_high" | Mail -s "***warning cluster temp: $temp > $temp_high" -r smokebot@nist.gov $mailTo
      fi
    fi
  fi
}

logdir=$HOME/.cluster_status
if [ "$arg" == "gettemp" ]; then
  cluster_host=`hostname -s`
  load=`tail -1 ~/.cluster_status/load_${cluster_host}.csv | awk -F',' '{print $2}'`
  temp=`tail -1 ~/.cluster_status/load_${cluster_host}.csv | awk -F',' '{print $3}'`
  tempcrit=88.0
  tempcrit_lock=tempcrit_lock
  if [ ! -e $tempcrit_lock ]; then
    if (( $(echo "$temp > $tempcrit" |bc -l) )); then
      touch $tempcrit_lock
      echo "***warning: cluster room temperature is greater than $temp_high" 
      if [ "$mailTo" != "" ]; then
        echo "***warning: cluster room temperature is greater than $temp_high" | Mail -s "***warning cluster temp: $temp > $temp_high" -r smokebot@nist.gov $mailTo
      fi
    fi
  fi
  WARN_TEMP 75.0 lock75
  WARN_TEMP 77.0 lock77
  WARN_TEMP 79.0 lock79
  WARN_TEMP 81.0 lock81
  WARN_TEMP 83.0 lock83
  WARN_TEMP 85.0 lock85
  WARN_TEMP 87.0 lock87
  WARN_TEMP 89.0 lock89
  WARN_TEMP 91.0 lock91

  if [[ "$daily" == "daily" ]] && [[ "$mailTo" != "" ]]; then
    echo "" | Mail -s "cluster check - temperature: $temp load: $load" $mailTo
  fi
fi
lockfile=$logdir/cluster_status_lock
if [ -e $lockfile ]; then
  echo "***error: cluster_status.sh script already running"
  echo "  exiting"
  exit
fi
touch $lockfile

if [ "$STATUS_WEBPAGE" == "" ]; then
  webpage=/var/www/html/summary.html
else
  webpage=$STATUS_WEBPAGE
fi
if [ "$STATUS_TEMP_IP" != "" ]; then
  TEMP_IP=$STATUS_TEMP_IP
fi

# ---------------------------------------------------------------------
# shouldn't have to modify any lines below

# ---------------------------- usage ----------------------------------

# error checking

function usage {
  echo " -h - show this message"
  echo " -i - initialize host status files"
  echo " -s - send out an email summarizing the cluster status"
  rm $lockfile
  exit
}
if [ "$webpage" == "" ]; then
  echo "***error: The summary web page location is not defined."
  echo "   Define the environment variable STATUS_WEBPAGE"
  echo "   use chown to make it owned by the user `whoami`"
  rm $lockfile
  exit
fi
if [ ! -e $webpage ]; then
  echo "***error: The summary web page $webpage does not exist."
  echo "   Define the environment variable STATUS_WEBPAGE"
  echo "   and use chown to make it owned by the user `whoami`"
  rm $lockfile
  exit
fi

DOWN_NODES=down_nodes.$$
UP_NODES=up_nodes.$$
ALL_NODES=all_nodes.$$

dshout=dsh.out.$$
nodeup=$logdir/node_up
nodedown=$logdir/node_down
upnow=$logdir/upnow
downnow=$logdir/downnow
summary=$logdir/summary
updir=$logdir/up
downdir=$logdir/down
INIT=
SUMMARY=
temp_up_file=/tmp/cluster_nodes.$$

while getopts 'his' OPTION
do
case $OPTION in
  h)
  usage
  ;;
  i)
  INIT=1
  ;;
  s)
  SUMMARY=1
  ;;
esac
done
shift $(($OPTIND-1))
DSH=dsh

source ./Get_Host_Status.sh $HOST_BASE $HOST_BEG $HOST_END $ALL_NODES $DOWN_NODES $UP_NODES

# create directories containing a file for each host that is either up or down/offline
mkdir -p $updir
mkdir -p $downdir

if  [ "$INIT" == "1" ]; then
  rm $updir/*
  rm $downdir/*
fi

rm -rf $summary
touch $summary

# get load on each node that is up (UP_HOST_LIST is generated in Get_Host_Status script)
#$DSH -f -e "cat /proc/loadavg" -w $UP_HOST_LIST  >& $dshout
pdsh -w "$UP_HOST_LIST" "cat /proc/loadavg"   >& $dshout
grep -v executing $dshout | awk  -F':' '{print $1," ", $2}' | awk -F' ' '{print $1," ",$2}'| grep -v dsh | sort > $nodeup

# get list of down nodes 
grep "couldn't connect" $dshout | awk '{print $5}' | awk -F':' '{print $1}' | sort > $nodedown

# merge in nodes that 'pbsnodes -l' reports are down/offline
cat $nodedown >> $DOWN_NODES
sort -u $DOWN_NODES > $nodedown
rm $DOWN_NODES
rm $UP_NODES
rm $ALL_NODES
rm $dshout

# look for nodes that are up

up_nodes=`cat $nodeup`
nup=`cat $nodeup | wc -l`

# the file upnow contains a list of hosts that just came up
rm -rf $upnow
touch $upnow
nlines=`cat $nodeup|wc -l`
if [ $nlines -gt 1  ]; then
while read entry; do
  host=`echo $entry | awk '{print $1}'`
  load=`echo $entry | awk '{print $2}'| awk -F',' '{print $1}'`
# if the host is not in the up directory then it just came up
  if [ ! -e $updir/$host ]; then
    echo $host >> $upnow
  fi
# if the host is up then it is not down so remove it from the $downdir directory
  rm -f $downdir/$host
# the directory $updir contains a file for each host that is up
# each of these files contains the current load
  echo $load > $updir/$host
done<$nodeup
fi

countup=`cat $upnow | wc -l`
if [[ $countup -gt 0 ]] && [[ "$INIT" == "" ]]; then
  echo "The following nodes came up:" >> $summary
  cat $upnow >> $summary
fi

# look for nodes that are down
# same logic as for up nodes but reversed

rm  -rf $downnow
touch $downnow
down_nodes=`cat $nodedown`
ndown=`cat $nodedown | wc -l`
for node in $down_nodes
do
if [ ! -e $downdir/$node ]; then
  touch $downdir/$node
  echo $node >> $downnow
fi
rm -f $updir/$node
done
countdown=`cat $downnow | wc -l`
if [[ $countdown -gt 0 ]] && [[ "$INIT" == "" ]]; then
  echo "" >> $summary
  echo "The following nodes went down:" >> $summary
  cat $downnow >> $summary
fi

countsummary=`cat $summary | wc -l`
if [ $countsummary -gt 0 ]; then
  COUNTUP=
  if [ $countup -gt 0 ]; then
    COUNTUP="$countup nodes came up"
    echo $COUNTUP
  fi
  if [ $countdown -gt 0 ]; then
    COUNTDOWN="$countdown nodes went down"
    echo $COUNTDOWN
  fi
  COMMA=
  if [[ $countup -gt 0 ]] && [[ $countdown -gt 0 ]]; then
    COMMA=", "
  fi
  if [[ "$INIT" == "" ]] && [[ "$mailTo" != "" ]]; then
    mail -s "Fire cluster status: $COUNTUP$COMMA$COUNTDOWN" $mailTo < $summary > /dev/null 
  fi
fi

if [[ "$SUMMARY" == "1" ]] && [[ "$mailTo" != "" ]]; then
  NUP=
  if [ $nup -gt 0 ]; then
    NUP="$nup nodes up"
  fi
  if [ $ndown -gt 0 ]; then
    NDOWN="$ndown nodes down"
  fi
  COMMA=
  if [[ $nup -gt 0 ]] && [[ $ndown -gt 0 ]]; then
    COMMA=", "
  fi
  mail -s "Fire cluster status: $NUP$COMMA$NDOWN" $mailTo < $summary > /dev/null  
fi
rm -f $summary $downnow $upnow $nodeup $nodedown
./make_summary.sh $webpage $TEMP_IP
rm $lockfile
