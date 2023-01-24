#!/bin/bash
TBEG=$1
TEND=$2
DIFF=$((TEND-TBEG))
HOURS=$(($DIFF / 3600))
MINUTES=$(($DIFF / 60))
MINUTES=$(($MINUTES % 60))
SEC=$(($DIFF % 60))
if [ $HOURS -lt 10 ]; then
  HOURS="0$HOURS"
fi
if [ $MINUTES -lt 10 ]; then
  MINUTES="0$MINUTES"
fi
if [ $SEC -lt 10 ]; then
  SEC="0$SEC"
fi
echo "${HOURS}:${MINUTES}:${SEC}"
