#!/bin/bash

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

export CHECK_CLUSTER=1
ETHOUT=/tmp/out.$$
FSOUT=/tmp/fsout.$$
IBOUT=/tmp/ibout.$$

# check ethernet
pdsh -t 2 -w $CB_HOSTS date   >& $ETHOUT
ETHDOWN=`grep timed  $ETHOUT | grep out | awk '{printf "%s%s", $6," " }'`

# check file systems
pdsh -t 2 -w $CB_HOSTS "df -k -t nfs | wc -l" |&  grep -v ssh | sort >& $FSOUT

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
  echo "all hosts are mounting $NF0 file systems ($CB_HOSTS)"
else
  echo "hosts not mounting $NF0 file systems: $FSDOWN"
fi

if [ "$ETHDOWN" == "" ]; then
  echo "all ethernet interfaces are working ($CB_HOSTS)"
else
  echo "hosts down(ETH): $ETHDOWN"
fi

# check infiniband
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
  IBDOWN=`grep timed  $IBOUT | grep out | awk '{printf "%s%s", $6," " }'`
  if [ "$IBDOWN" == "" ]; then
    echo "all infiniband interfaces are working ($CB_HOSTIB1$CB_HOSTB2$CB_HOSTIB3$CB_HOSTIB4)"
  else
    echo "hosts down(IB): $IBDOWN"
  fi
fi

# cleanup
rm -f $FSOUT $ETHOUT $IBOUT
