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
  disksize=`du -ks $ROOTDISK/$user`
  size=`echo $disksize | awk -F ' ' '{print $1}'`
  gbsize=$((size/1000000))
  disk=`echo $disksize | awk -F ' ' '{print $2}'`
  echo $gbsize GB $user >> $logfile
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
