#!/bin/bash
case=$1
caseout=$case.out

MAXTIME=600

#---------------------------------------------
#                   GET_DURATION
#---------------------------------------------

GET_DURATION(){
  local time_before=$1
  local time_after=$2

  DIFF_TIME=`echo $(($time_after-$time_before))`
  echo $DIFF_TIME
}

curtime=`date +%s`
if [ ! -e $caseout ]; then
  exit 0
fi
nstop=`tail -1 $caseout | grep STOP | wc -l`
if [ $nstop -EQ 1 ]; then
  exit 0
fi

filetime=`date -r $caseout  "+%s"`
difftime=`GET_DURATION $filetime $curtime`
if [ $difftime -GT $MAXTIME ]; then
  exit 1
fi
exit 0
