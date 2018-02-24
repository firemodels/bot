#!/bin/bash

# 1.  create empty CLUSTER_NODES and webpage files owned by 
#     user running this script.  Note, this script uses the pbsnodes
#     command to determine nodes in the cluster to check
# 2.  first time you run this script use -i option to initialize host status files
# 3.  define mailTo variable if mail is set up
# 4.  define TEMP_IP variable if you have a temperature sensor
#     (script will skip over temperature plot generation if TEMP_IP is set to null)

CLUSTER_NODES=/usr/local/dsh/node_groups/CLUSTER_NODES
webpage=/var/www/html/summary.html

mailTo="gforney@gmail.com 3018070456@vtext.com"
# set mailTo to blank if mail is not set up
# mailTo=

TEMP_IP=129.6.159.193/temp
# set TEMP_IP to null if you don't have a temperature sensor
# TEMP_IP=null

# ---------------------------------------------------------------------
# shouldn't have to modify any lines below

# ---------------------------- usage ----------------------------------
function usage {
  echo " -h - show this message"
  echo " -i - initialize host status files"
  echo " -s - send out an email summarizing the cluster status"
  exit
}

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
