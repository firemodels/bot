#!/bin/bash
#---------------------------------------------
#                   usage
#---------------------------------------------

function usage {
  echo "Usage: get_logs.sh"
  echo ""
  echo "get_logs.sh"
  echo ""
  echo " -a date - include revisions after date dd-mon-yyyy e.g. 17-Nov-2021"
  echo " -b date - include revisions before date dd-mon-yyyy [default: current date]"
  echo " -n n    - maximum number of revisions [default: $MAXN]"
  echo " -h      - show this message"
  echo " -r revs - file containing revisions used to build fds [default: $REVISIONS]"
  exit
}

REVISIONS=revisions.txt
MAXN=100
AFTER=1-Jan-2021
BEFORE=

#*** read in parameters from command line

while getopts 'a:b:n:hr:' OPTION
do
case $OPTION  in
  a)
   AFTER="$OPTARG"
   ;;
  b)
   BEFORE="$OPTARG"
   ;;
  h)
   usage
   exit
   ;;
  n)
   MAXN="$OPTARG"
   ;;
  r)
   REVISIONS="$OPTARG"
   ;;
esac
done
shift $(($OPTIND-1))

if [ "$AFTER" != "" ]; then
  AFTER="--after=$AFTER"
fi
if [ "$BEFORE" != "" ]; then
  BEFORE="--before=$BEFORE"
fi

CURDIR=`pwd`
cd ../../fds
FDSREPO=`pwd`
cd $FDSREPO
TEMPREVS=/tmp/revs.$$
TEMPREVS2=/tmp/revs2.$$
git log --no-merges --date=short  $AFTER $BEFORE  --format="%h;%cnn;%cd;%s" Source > $TEMPREVS
NL=`cat $TEMPREVS | wc -l`
if [ $NL -gt $MAXN ]; then
  SKIP=`expr $NL / $MAXN`
  awk -v NUM=$SKIP 'NR %NUM == 0' $TEMPREVS | head -$MAXN > $CURDIR/$REVISIONS
else
  cp $TEMPREVS $CURDIR/$REVISIONS
fi
rm $TEMPREVS
