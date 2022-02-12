#!/bin/bash
#---------------------------------------------
#                   usage
#---------------------------------------------

function usage {
  echo "Usage: get_revisions.sh [options]"
  echo "       get_revisions.sh generates a list of fds or smv revisions"
  echo "       committed between optionally specified dates.  The file"
  echo "       generated is used by the script revbot.sh to build and run"
  echo "       multiple versions of fds, one version for each repo"
  echo "       revision or to build multiple versions of smokeview"
  echo ""
  echo "Options:"
  echo ""
  echo " -a date - include revisions after date [default: $AFTERARG]"
  echo " -b date - include revisions before date [default: $BEFOREARG]"
  echo " -n n    - maximum number of revisions to include [default: $MAXN]"
  echo " -h      - show this message"
  echo " -r repo - generate revisions for repo [default: $REPO]"
  echo "           A list of revisions are outputted to $REVISIONS"
  exit
}

MAXN=10
AFTERARG=1-Jan-2021
BEFOREARG=`date +%d-%b-%Y`
AFTERARG=`date -d "-3 month" +%d-%b-%Y`
REPO=fds
REVISIONS=${REPO}_revisions.txt
MAXN=10

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
   REPO="$OPTARG"
   ;;
esac
done
shift $(($OPTIND-1))

REVISIONS=${REPO}_revisions.txt

if [ "$AFTERARG" != "" ]; then
  AFTER="--after=$AFTERARG"
fi
if [ "$BEFOREARG" != "" ]; then
  BEFORE="--before=$BEFOREARG"
fi

CURDIR=`pwd`

REPODIR=../../$REPO
if [ ! -d $REPODIR ]; then
  echo "***error: The repo ../../$REPO does not exist"
  exit
exist
  cd $REPODIR
  REPODIR=`pwd`
fi

cd $REPODIR
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
