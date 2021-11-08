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

if [ ! -d $HOME/.clusterbot ]; then
  mkdir $HOME/.clusterbot
fi
OUTPUT=$HOME/.clusterbot/clusterbot.out

cd $BINDIR

echo updating bot repo
git fetch origin        &> /dev/null
git merge origin/master &> /dev/null

echo "Revision: $REV" > $HEAD
./clusterbot.sh | tee  $OUTPUT

nerrors=`grep ***Error $OUTPUT | wc -l`
nwarnings=`grep ***Warning $OUTPUT | wc -l`
if [ "$EMAIL" != "" ]; then
  echo emailing results to $EMAIL
  cat $OUTPUT | mail -s "$CB_HOSTS status: $nerrors Errrors, $nwarnings Warnings" $EMAIL
fi

cd $CURDIR
