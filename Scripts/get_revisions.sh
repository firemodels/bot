#!/bin/bash
#---------------------------------------------
#                   usage
#---------------------------------------------

function usage {
  echo "Usage: get_revisions.sh"
  echo ""
  echo "get_revisions.sh"
  echo ""
  echo " -a date - include revisions after date [default: $AFTERARG]"
  echo " -b date - include revisions before date [default: $BEFOREARG]"
  echo " -n n    - maximum number of revisions to include [default: $MAXN]"
  echo " -h      - show this message"
  echo " -r revs - file containing revisions used to build fds [default: $REVISIONS]"
  exit
}

REVISIONS=revisions.txt
MAXN=10
AFTERARG=1-Jan-2021
BEFOREARG=`date +%d-%b-%Y`
AFTERARG=`date -d "-3 month" +%d-%b-%Y`

#*** read in parameters from command line

while getopts 'a:b:n:hr:' OPTION
do
case $OPTION  in
  a)
   AFTERARG="$OPTARG"
   ;;
  b)
   BEFOREARG="$OPTARG"
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

if [ "$AFTERARG" != "" ]; then
  AFTER="--after=$AFTERARG"
fi
if [ "$BEFOREARG" != "" ]; then
  BEFORE="--before=$BEFOREARG"
fi

CURDIR=`pwd`
cd ../../fds
FDSREPO=`pwd`
cd $FDSREPO
TEMPREVS=/tmp/revs.$$

echo "Outputting $MAXN revisions between $AFTERARG and $BEFOREARG to $REVISIONS"
git log --no-merges --date=short  $AFTER $BEFORE  --format="%h;%cnn;%cd;%s" Source > $TEMPREVS
NL=`cat $TEMPREVS | wc -l`
if [ $NL -gt $MAXN ]; then
  SKIP=`expr $NL / $MAXN`
  awk -v NUM=$SKIP 'NR %NUM == 0' $TEMPREVS | head -$MAXN > $CURDIR/$REVISIONS
else
  cp $TEMPREVS $CURDIR/$REVISIONS
fi
rm $TEMPREVS
