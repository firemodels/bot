#!/bin/bash

# 1.  define the STATUS_CLUSTER_NODES environment variable pointing to a 
#     dsh nodes file. chown this file to the user running this script.
#     Note, this script puts host entries into this file using the pbsnodes
#     command to determine the nodes in the cluster
#     example: 
#        export STATUS_CLUSTER_NODES=/usr/local/dsh/nodes_groups_CLUSTER_NODES
# 2.  define the STATUS_WEBPAGE containing webpage for summary results
#     produced by this script
#     example: 
#        export STATUS_WEBPAGE=/var/www/html/summary.html
# 3.  define the STATUS_MAILTO environment variable containing an email
#     address to email results too.
#     example: 
#        export STATUS_MAILTO=user@gmail.com
# 4.  define the STATUS_TEMP_IP variable if you have a temperature sensor
#     (this script will not generate temperature plots if STATUS_TEMP_IP
#     is blank)

logdir=$HOME/.cluster_status
lockfile=$logdir/cluster_status_lock
if [ -e $lockfile ]; then
  echo "***error: cluster_status.sh script already running"
  echo "  exiting"
  exit
fi
touch $lockfile

if [ "$STATUS_CLUSTER_NODES" == "" ]; then
  CLUSTER_NODES=/usr/local/dsh/node_groups/CLUSTER_NODES
else
  CLUSTER_NODES=$STATUS_CLUSTER_NODES
fi

if [ "$STATUS_WEBPAGE" == "" ]; then
  webpage=/var/www/html/summary.html
else
  webpage=$STATUS_WEBPAGE
fi
if [ "$STATUS_MAILTO" != "" ]; then
  mailTo=$STATUS_MAILTO
fi
if [ "$STATUS_TEMP_IP" != "" ]; then
  TEMP_IP=$STATUS_TEMP_IP
fi

# ---------------------------------------------------------------------
# shouldn't have to modify any lines below

# ---------------------------- usage ----------------------------------

# error checking

if [ "$CLUSTER_NODES" == "" ]; then
  echo "***error: The dsh parameter file does not exist."
  echo "   Define the environment variable STATUS_CLUSTER_NODES"
  echo "   use chown to make it owned by the user `whoami`."
  rm $lockfile
  exit
fi
if [ ! -e $CLUSTER_NODES ]; then
  echo "***error: The dsh parameter file "
  echo "  $STATUS_CLUSTER_NODES"
  echo "  does not exist. Define the environment variable STATUS_CLUSTER_NODES"
  echo "  and use chown to make it owned by the user `whoami`."
  rm $lockfile
  exit
fi
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

CLUSTER_NODES_BASE=$(basename "$CLUSTER_NODES")
CLUSTER_NODES_DOWN=/tmp/cluster_nodes_down.$$
dshout=dsh.out
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

# use the pbsnodes command to generate a list of nodes that are up or down/offline

# up nodes
pbsnodes -l free | awk '{print $1}'           > $temp_up_file
pbsnodes -l job-exclusive | awk '{print $1}'  >>$temp_up_file
pbsnodes -l job-sharing | awk '{print $1}'    >>$temp_up_file
pbsnodes -l busy | awk '{print $1}'           >>$temp_up_file
pbsnodes -l time-shared | awk '{print $1}'    >>$temp_up_file
sort -u $temp_up_file > $CLUSTER_NODES
rm $temp_up_file

# down/offline nodes (we'll later check the up node list for any nodes that are really down)
pbsnodes -l | awk '{print $1}' | sort -u   > $CLUSTER_NODES_DOWN

# create directories containing a file for each host that is either up or down/offline
mkdir -p $updir
mkdir -p $downdir

if  [ "$INIT" == "1" ]; then
  rm $updir/*
  rm $downdir/*
fi

rm -rf $summary
touch $summary

# run the 'w' command on each node that is up (to get the load)
dsh -N $CLUSTER_NODES_BASE -f -e "w | head -1"  >& $dshout
grep users $dshout | grep -v executing | awk  -F':' '{print $1 $NF}' | sort > $nodeup

# get list of down nodes 
grep "couldn't connect" $dshout | awk '{print $5}' | awk -F':' '{print $1}' | sort > $nodedown

# merge in nodes that 'pbsnodes -l' reports are down/offline
cat $nodedown >> $CLUSTER_NODES_DOWN
sort -u $CLUSTER_NODES_DOWN > $nodedown
rm $CLUSTER_NODES_DOWN
rm $dshout

# look for nodes that are up

up_nodes=`cat $nodeup`
nup=`cat $nodeup | wc -l`

# the file upnow contains a list of hosts that just came up
rm -rf $upnow
touch $upnow
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
rm $summary $downnow $upnow $nodeup $nodedown
./make_summary.sh $webpage $TEMP_IP
rm $lockfile
