#!/bin/bash

#---------------------------------------------
# ---------------------------- usage ----------------------------------
#---------------------------------------------

function usage {
  echo "Usage: clusterbot.sh "
  echo ""
  echo "clusterbot.sh - perform various checks on a Linux cluster"
  echo ""
  echo " -h - display this message"
  echo " -m email_address - send results to email_address"
  exit
}


EMAIL=
while getopts 'hm:' OPTION
do
case $OPTION  in
  m)
   EMAIL="$OPTARG"
   ;;
  h)
   usage
   exit
   ;;
esac
done
shift $(($OPTIND-1))


CURDIR=`pwd`

BINDIR=$CURDIR/`dirname "$0"`
cd $BINDIR
BINDIR=`pwd`
cd $CURDIR

TEST=$BINDIR/test.$$
touch $TEST
if [ -e $TEST ]; then
  rm $TEST
  OUTPUT=$BINDIR/clusterbot.out
else
  if [ ! -d $HOME/.clusterbot ]; then
    mkdir $HOME/.clusterbot
  fi
  OUTPUT=$HOME/.clusterbot/clusterbot.out
fi
cd $BINDIR

echo updating bot rep
git fetch origin        &> /dev/null
git merge origin/master &> /dev/null

REV=`git describe --dirty --long`

./clusterbot.sh | tee  $OUTPUT
if [ "$EMAIL" != "" ]; then
  echo emailing results to $EMAIL
  cat $OUTPUT | mail -s "clusterbot status: $CB_HOSTS - $REV" $EMAIL
fi

cd $CURDIR
