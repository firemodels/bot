#!/bin/bash

# environment varibles used by script
# 1.  STATUS_WEBPAGE - webpage conaining summary results
#     example: 
#        export STATUS_WEBPAGE=/var/www/html/summary.html
# 2.  STATUS_MAILTO email address where results are sent to.
#     example: 
#        export STATUS_MAILTO=user@gmail.com
# 3.  STATUS_TEMP_IP ip address of a temperature sensor (optional)
#     temperature plots are not generated if STATUS_TEMP_IP is blank)

WARN_TEMP ()
{
  local temp_high=$1
  local temphigh_lock=$2
  if [ ! -e $temphigh_lock ]; then
    if (( $(echo "$temp > $temp_high" |bc -l) )); then
      touch $temphigh_lock
      echo "" | Mail -s "***warning temp: $temp" $STATUS_MAILTO
    fi
  fi
}

# ---------------------------- usage ----------------------------------

function usage {
  echo " generate a web page summarizing cluster status usage"
  echo " -b - first node index - default: $HOST_BEG"
  echo " -e - last node index - default: $HOST_END"
  echo " -H - base name of compute nodes - default: $HOST_BASE"
  echo " -h - show this message"
  echo " -i - reset host status files (files containing hosts that are up and down)"
if [ "$STATUS_MAILTO" != "" ]; then
  echo " -m email_address - default: $STATUS_MAILTO"
else
  echo " -m email_address"
fi
  echo " -o - option - daily, none, gettemp"
  echo " -s - send out an email summarizing the cluster status"
if [ "$STATUS_TEMP_IP" != "" ]; then
  echo " -t temp_ip_address - default: $STATUS_TEMP_IP"
else
  echo " -t temp_ip_address "
fi
  echo " -v - show parameters used to run script - do not run script"
if [ "$STATUS_WEBPAGE" != "" ]; then
  echo " -w webpage - default: $STATUS_WEBPAGE"
else
  echo " -w webpage"
fi
echo "example:"
echo "./cluster_status.sh -H blaze -b 1 -e 144 -m user@nist.gov"
  rm -f $lockfile
  exit
}

DOWN_NODES=down_nodes.$$
UP_NODES=up_nodes.$$
ALL_NODES=all_nodes.$$

dshout=dsh.out.$$
logdir=$HOME/.cluster_status
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
HOST_BASE=`hostname -s`
HOST_BEG=1
HOST_END=1
logdir=$HOME/.cluster_status
if [ ! -d $logdir ]; then
  mkdir $logdir
fi
lockfile=$logdir/cluster_status_lock
locksummaryfile=$logdir/lockfile_make_summary
SHOW_PARAMS=

while getopts 'b:e:fhH:im:o:st:vw:' OPTION
do
case $OPTION in
  b)
  HOST_BEG="$OPTARG"
  ;;
  e)
  HOST_END="$OPTARG"
  ;;
  f)
  rm -f $lockfile
  rm -f $locksummaryfile
  ;;
  H)
  HOST_BASE="$OPTARG"
  ;;
  h)
  usage
  ;;
  i)
  INIT=1
  ;;
  m)
  STATUS_MAILTO="$OPTARG"
  ;;
  o)
  scriptoption="$OPTARG"
  if [[ "$scriptoption" != "daily" ]] && [[ "$scriptoption" != "gettemp" ]]; then
    scriptoption="none"
  fi
  ;;
  s)
  SUMMARY=1
  ;;
  t)
  STATUS_TEMP_IP="$OPTARG"
  ;;
  v)
  SHOW_PARAMS=1
  ;;
  w)
  STATUS_WEBPAGE="$OPTARG"
  ;;
esac
done
shift $(($OPTIND-1))

error=
dsh_missing=`dsh  -h |& grep 'command not' | wc -l`
if [ "$dsh_missing" == "1" ]; then
  echo "***error: dsh command not found"
  error=1
fi

if [ "$STATUS_TEMP_IP" == "" ]; then
  if [ "$scriptoption" == "gettemp" ]; then
     echo "***error: temperature sensor not available"
     echo " use -o daily or -o none"
     error=1
  fi
fi

if [ "$STATUS_MAILTO" == "" ]; then
     echo "***error: email mailto address not defined"
     echo " define STATUS_MAILTO or use the -m option"
     error=1
fi

if [ "$STATUS_WEBPAGE" == "" ]; then
     echo "***error: STATUS_WEBPAGE variable not defined"
     echo " define STATUS_WEBPAGE or use the -w option"
     error=1
else
     have_webpage=`touch $STATUS_WEBPAGE |& grep 'Permission denied' | wc -l`
     if [ $have_webpage -gt 0 ]; then
       echo "***error: unable to write to $STATUS_WEBPAGE"
       echo "  change ownership of $STATUS_WEBPAGE so that `whoami` has write permission"
       ls -l $STATUS_WEBPAGE
       error=1
     fi
fi

if [ -e $lockfile ]; then
  echo "***error: cluster_status.sh script already running (lock file exists)"
  echo "  use the -f option if this is not the case"
  error=1
fi

if [ "$error" != "" ]; then
  SHOW_PARAMS=1
  echo 
fi

if [ "$SHOW_PARAMS" != "" ]; then
  echo "Settings"
  echo "--------"
  echo "     HOST_BASE: $HOST_BASE"
  echo "      HOST_BEG: $HOST_BEG"
  echo "      HOST_END: $HOST_END"
  echo " STATUS_MAILTO: $STATUS_MAILTO"
  if [ "$STATUS_TEMP_IP" != "" ]; then
    echo "STATUS_TEMP_IP: $STATUS_TEMP_IP"
  fi
  echo "STATUS_WEBPAGE: $STATUS_WEBPAGE"
  if [ "$error" == "" ]; then
    exit
  fi
fi

if [ "$error" != "" ]; then
  echo
  echo script aborted
  exit
fi

if [ "$scriptoption" == "gettemp" ]; then
  load=`tail -1 ~/.cluster_status/load_status.csv | awk -F',' '{print $2}'`
  temp=`tail -1 ~/.cluster_status/load_status.csv | awk -F',' '{print $3}'`
  tempcrit=88.0
  tempcrit_lock=tempcrit_lock
  if [ ! -e $tempcrit_lock ]; then
    if (( $(echo "$temp > $tempcrit" |bc -l) )); then
      touch $tempcrit_lock
      echo "" | Mail -s "***warning temp: $temp" gforney@gmail.com  randy.mcdermott@gmail.com
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

  echo "" | Mail -s "cluster check - temperature: $temp load: $load" $STATUS_MAILTO
  exit
fi
touch $lockfile

webpage=$STATUS_WEBPAGE
mailTo=$STATUS_MAILTO
if [ "$STATUS_TEMP_IP" != "" ]; then
  TEMP_IP=$STATUS_TEMP_IP
fi

# ---------------------------------------------------------------------
# shouldn't have to modify any lines below

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
$DSH -f -e "cat /proc/loadavg" -w $UP_HOST_LIST  >& $dshout
grep -v executing $dshout | awk  -F':' '{print $1," ", $2}' | awk -F' ' '{print $1," ",$2}'| grep -v dsh | sort > $nodeup

# get list of down nodes 
grep "couldn't connect" $dshout | awk '{print $5}' | awk -F':' '{print $1}' | sort > $nodedown

# merge in nodes that 'sinfo' reports are down/offline
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
./make_summary.sh $HOST_BASE $HOST_BEG $HOST_END $webpage $TEMP_IP
rm $lockfile
