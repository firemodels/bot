#!/bin/bash

# --------------------- define file names --------------------

ETHOUT=/tmp/out.$$
FSOUT=/tmp/fsout.$$
IBOUT=/tmp/ibout.$$
SLURMOUT=/tmp/slurmout.$$
DOWN_HOSTS=/tmp/downhosts.$$
UP_HOSTS=/tmp/uphosts.$$

# --------------------- initial error checking --------------------

ERROR=
if [ "$CB_HOSTS" == "" ]; then
  ERROR=1
  echo "***error: environment variable CB_HOSTS not defined"
fi
if [ "$CB_HOST1" != "" ]; then
  HAVE_IB=1
  if [ "$CB_HOSTIB1" == "" ]; then
    ERROR=1
    echo "***error: CB_HOSTIB1 must be defined if CB_HOST1 is defined"
  fi
fi
if [ "$CB_HOST2" != "" ]; then
  HAVE_IB=1
  if [ "$CB_HOSTIB2" == "" ]; then
    ERROR=1
    echo "***error: CB_HOSTIB2 must be defined if CB_HOST2 is defined"
  fi
fi
if [ "$CB_HOST3" != "" ]; then
  HAVE_IB=1
  if [ "$CB_HOSTIB3" == "" ]; then
    ERROR=1
    echo "***error: CB_HOSTIB3 must be defined if CB_HOST3 is defined"
  fi
fi
if [ "$CB_HOST4" != "" ]; then
  HAVE_IB=1
  if [ "$CB_HOSTIB4" == "" ]; then
    ERROR=1
    echo "***error: CB_HOSTIB4 must be defined if CB_HOST4 is defined"
  fi
fi
if [ "$ERROR" == "1" ]; then
  exit
fi

echo
echo "--------------- cluster status $CB_HOSTS ---------------"

# --------------------- check ethernet --------------------

pdsh -t 2 -w $CB_HOSTS date   >& $ETHOUT
ETHDOWN=`grep timed  $ETHOUT | grep out | awk '{printf "%s%s", $6," " }'`
if [ "$ETHDOWN" == "" ]; then
  echo "Ethernet up on all hosts"
  ACCESSIBLE=" "
else
  echo "Ethernet down on: $ETHDOWN"
  ACCESSIBLE=" accessible "
fi

# --------------------- check infiniband --------------------

if [ "$HAVE_IB" == "1" ]; then
  echo "" > $IBOUT
  if [ "$CB_HOST1" != "" ]; then
    ssh $CB_HOST1 pdsh -t 2 -w $CB_HOSTIB1 date  >>  $IBOUT 2>&1
  fi
  if [ "$CB_HOST2" != "" ]; then
    ssh $CB_HOST2 pdsh -t 2 -w $CB_HOSTIB2 date  >>  $IBOUT 2>&1
  fi
  if [ "$CB_HOST3" != "" ]; then
    ssh $CB_HOST3 pdsh -t 2 -w $CB_HOSTIB3 date  >>  $IBOUT 2>&1
  fi
  if [ "$CB_HOST4" != "" ]; then
    ssh $CB_HOST4 pdsh -t 2 -w $CB_HOSTIB4 date  >>  $IBOUT 2>&1
  fi
  IBDOWN=`grep timed  $IBOUT | grep out | sort | awk '{printf "%s%s", $6," " }'`
  if [ "$IBDOWN" == "" ]; then
    echo "Infiniband up on all${ACCESSIBLE}hosts"
  else
    echo "Infiniband down on: $IBDOWN"
  fi
fi

# --------------------- check file systems --------------------

pdsh -t 2 -w $CB_HOSTS "df -k -t nfs | tail -n +2 | wc -l" |&  grep -v ssh | sort >& $FSOUT
cat $FSOUT | awk -F':' '{print $1}' > $UP_HOSTS

NF0=`head -1 $FSOUT | awk '{print $2}'`
FSDOWN=
while read line 
do
  host=`echo $line | awk '{print $1}'`
  host=`echo $host | sed 's/.$//'`
  NFI=`echo $line | awk '{print $2}'`
  if [ "$NFI" != "$NF0" ]; then
    FSDOWN="$FSDOWN $host"
  fi
done < $FSOUT

if [ "$FSDOWN" == "" ]; then
  echo "$NF0 file systems mounted on all${ACCESSIBLE}hosts"
else
  echo "Hosts not mounting $NF0 file systems: $FSDOWN"
fi

# --------------------- check slurm --------------------

pbsnodes -l | awk '{print $1}' | sort -u  > $DOWN_HOSTS
DOWN_HOST_LIST=`grep -f $DOWN_HOSTS $UP_HOSTS`

if [ "$DOWN_HOST_LIST" == "" ]; then
  echo "Slurm up on all${ACCESSIBLE}hosts"
else
  echo "hosts down(slurm): $DOWN_HOST_LIST"
fi

# --------------------- check slurm daemon --------------------

pdsh -t 2 -w $CB_HOSTS "ps -el | grep slurmd | wc -l" |&  grep -v ssh | sort >& $SLURMOUT
SLURMDOWN=
while read line 
do
  host=`echo $line | awk '{print $1}'`
  host=`echo $host | sed 's/.$//'`
  NSLURM=`echo $line | awk '{print $2}'`
  if [ "$NSLURM" == "0" ]; then
    SLURMDOWN="$SLURMDOWN $host"
  fi
done < $SLURMOUT
if [ "$SLURMDOWN" == "" ]; then
  echo "slurmd running on all${ACCESSIBLE}hosts"
else
  echo "slurmd down on: $SLURMDOWN"
fi

# --------------------- cleanup --------------------

rm -f $DOWN_HOSTS $UP_HOSTS $SLURMOUT $FSOUT $ETHOUT $IBOUT
