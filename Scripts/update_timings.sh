#!/bin/bash

#---------------------------------------------
#                   usage
#---------------------------------------------

function usage {
echo "update base timing file"
echo ""
echo "Options:"
echo "-h - display this message"
if [ "$TIMING_FILE" == "" ]; then
  echo "-f file - timing file [default: most recent]"
else
  echo "-f file - timing file [default: $TIMING_FILE]"
fi
echo "-t dir - timing directory [default: $TIMING_DIR]"
exit 0
}

CURDIR=`pwd`
cd ../..
TO_ROOT=`pwd`
cd $CURDIR
TIMING_DIR=~firebot/.firebot/history
TIMING_FILE=
FIG_REPO=$TO_ROOT/fig
TO_DIR=$FIG_REPO/compare/firebot/times
if [ -e $TIMING_DIR ]; then
  TIMING_FILE=`ls -rth $TIMING_DIR/*_timing.csv | tail -1`
  TIMING_FILE=`basename $TIMING_FILE`
fi

#*** parse options

while getopts 'f:ht:' OPTION
do
case $OPTION  in
  f)
   TIMING_FILE="$OPTARG"
   ;;
  h)
   usage;
   ;;
  t)
   TIMING_DIR="$OPTARG"
   ;;
esac
done
shift $(($OPTIND-1))

ERROR=

if [ ! -d  $FIG_REPO ]; then
  echo "***error: $FIG_REPO does not exist"
  ERROR=1
fi
if [ ! -d  $TO_DIR ]; then
  echo "***error: $TO_DIR does not exist"
  ERROR=1
fi
if [ ! -e  $TIMING_DIR/$TIMING_FILE ]; then
  echo "***error: $TIMING_DIR/$TIMING_FILE  does not exist"
  ERROR=1
fi

if [ "$ERROR" == "1" ]; then
  exit
fi

echo "from directory: $TIMING_DIR"
echo "  to directory: $TO_DIR"
echo copying $TIMING_FILE  to base_times.csv
cp $TIMING_DIR/$TIMING_FILE  $TO_DIR/base_times.csv

FDS_REVISION=`echo $TIMING_FILE | awk -F'_' '{print $1}'`
echo copying $FDS_REVISION to FDS_REVISION
echo $FDS_REVISION > $TO_DIR/FDS_REVISION
