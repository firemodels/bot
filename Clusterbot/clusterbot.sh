#!/bin/bash

ETHOUT=/tmp/out.$$
FSOUT=/tmp/fsout.$$
IBOUT=/tmp/ibout.$$

# check ethernet
pdsh -t 2 -w blaze[001-144] date   >& $ETHOUT
ETHDOWN=`grep timed  $ETHOUT | grep out | awk '{printf "%s%s", $6," " }'`

# check file systems
pdsh -t 2 -w blaze[001-144] "df -k -t nfs | wc -l" |&  grep -v ssh | sort >& $FSOUT

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
  echo "all hosts are mounting $NF0 file systems"
else
  echo "hosts not mounting $NF0 file systems: $FSDOWN"
fi

if [ "$ETHDOWN" == "" ]; then
  echo "all ethernet interfaces are working"
else
  echo "hosts down(ETH): $ETHDOWN"
fi

# check infiniband
echo "" > $IBOUT
ssh blaze001 pdsh -t 2 -w blaze[001-036]-ib date  >>  $IBOUT 2>&1
ssh blaze037 pdsh -t 2 -w blaze[037-072]-ib date  >>  $IBOUT 2>&1
ssh blaze073 pdsh -t 2 -w blaze[073-108]-ib date  >>  $IBOUT 2>&1
ssh blaze109 pdsh -t 2 -w blaze[109-144]-ib date  >>  $IBOUT 2>&1
IBDOWN=`grep timed  $IBOUT | grep out | awk '{printf "%s%s", $6," " }'`
if [ "$IBDOWN" == "" ]; then
  echo "all infiniband interfaces are working"
else
  echo "hosts down(IB): $IBDOWN"
fi

# cleanup
rm -f $FSOUT $ETHOUT $IBOUT
