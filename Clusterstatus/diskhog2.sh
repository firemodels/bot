#!/bin/bash

function usage {
echo "Compute directory sizes"
echo ""
echo "Usage:"
echo "$0 [options]"
echo "Compute disk sizes"
echo ""
echo "Options:"
echo "-d dir - compute disk sizes for directories in dir [default: $ROOTDISK]"
echo "-h - display this message"
echo "-m mailto - email results to mailto "
echo "-o file - output results to file named output [default: $outfile]"
exit
}

#---------------------------------------------
#                   GET_TIME
#---------------------------------------------

GET_TIME(){
  echo $(date +"%s")
}

#---------------------------------------------
#                   GET_DURATION
#---------------------------------------------

GET_DURATION(){
  local time_before=$1
  local time_after=$2
  local __var=$3

  DELTA_TIME=`echo $(($time_after-$time_before))`
  TIME_H=`echo $(($DELTA_TIME / 3600 ))`
  TIME_M=`echo $((($DELTA_TIME % 3600 ) / 60))`
  TIME_S=`echo $(($DELTA_TIME % 60 ))`
  if (( "$DELTA_TIME" >= 3600 )) ; then
    DIFF_TIME="${TIME_H}h ${TIME_M}m ${TIME_S}s"
  else
    if (( "$DELTA_TIME" >= 60 )) ; then
      DIFF_TIME="${TIME_M}m ${TIME_S}s"
    else
      DIFF_TIME="${TIME_S}s"
    fi
  fi
  eval ${__var}_DIFF="'${DIFF_TIME}'"
  eval ${__var}_DELTA="'${DELTA_TIME}'"
}


TBEG=`date`
MAILTO_ARG=
MAILTO_ONE="gforney@gmail.com"
MAILTO_ALL="gforney@gmail.com randy.mcdermot@gmail.com mcgatta@gmail.com marcos.vanella@nist.gov"
MAXSIZE=70
outfile=/tmp/outfile
ROOTDISK=/home
if [ "$DH_HOME" != "" ]; then
  ROOTDISK=$DH_HOME
fi

while getopts 'd:hm:o:' OPTION
do
case $OPTION  in
  h)
   usage;
   ;;
  m)
   MAILTO_ARG=$OPTARG
   ;;
  o)
   outfile=$OPTARG
   ;;
  d)
   ROOTDISK=$OPTARG
   ;;
esac
done
shift $(($OPTIND-1))

# Inputs
HOST=`hostname`
SHORTHOST=`hostname -s`
echo $HOST > $outfile
logfile=/tmp/dh_log.$$
PERCEN='%'

TOTALSIZE=`df -k | grep -w $ROOTDISK | awk '{print $5}' | awk -F% '{print $1}'`
echo "$SHORTHOST:$ROOTDISK size: $TOTALSIZE$PERCEN" >> $outfile

# Check all hosts
for user in `ls $ROOTDISK`
do
  STIME_BEG=`GET_TIME`
  disksize=`du -ksx $ROOTDISK/$user`
  size=`echo $disksize | awk -F ' ' '{print $1}'`
  gbsize=$((size/1000000))
  disk=`echo $disksize | awk -F ' ' '{print $2}'`
  STIME_END=`GET_TIME`
  GET_DURATION $STIME_BEG $STIME_END USER
  echo $gbsize GB $user $USER_DIFF>> $logfile
done
TEND=`date`

echo "Start Time: $TBEG" >> $outfile
echo "  End Time: $TEND" >> $outfile
echo "                 " >> $outfile
sort -n -k 1 -r $logfile >> $outfile

if [ $TOTALSIZE -gt $MAXSIZE ]; then
  SUBJECT="***Warning: $TOTALSIZE$PERCEN > $MAXSIZE$PERCEN $SHORTHOST:$ROOTDISK"
  MAILTO=$MAILTO_ALL
else
  SUBJECT="$SHORTHOST:$ROOTDISK $TOTALSIZE$PERCEN"
  MAILTO=$MAILTO_ONE
fi
if [ "$MAILTO_ARG" != "" ]; then
  MAILTO=$MAILTO_ARG
fi

if [ "$MAILTO" != "" ]; then
  cat $outfile | mail -s "$SUBJECT" $MAILTO > /dev/null
fi
rm -f $logfile
