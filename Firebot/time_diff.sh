#!/bin/bash
TBEG=$1
TEND=$2

#------------------------------------------------------
#                 CONVERT
#------------------------------------------------------
CONVERT ()
{
  ARG=$1
  ARG2=$2
  if [ "$ARG" == "0" ]; then
    ARG=""
  else
    ARG=$ARG$ARG2
  fi
  echo $ARG
}

DIFF=$((TEND-TBEG))
HOURS=`CONVERT $(($DIFF / 3600)) h`
MINUTES=$(($DIFF / 60))
MINUTES=`CONVERT $(($MINUTES % 60)) m`
SEC=`CONVERT $(($DIFF % 60)) s`
echo $HOURS $MINUTES $SEC
