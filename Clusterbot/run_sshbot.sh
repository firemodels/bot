#!/bin/bash

#---------------------------------------------
# ---------------------------- USAGE ----------------------------------
#---------------------------------------------

function USAGE {
  echo "Usage: run_smokebot.sh [options]"
  echo ""
  echo "run_sshbot.sh - check ssh configuration parameters"
  echo ""
  echo "Options:"
  echo " -f - override lock to force clusterbot run"
  echo " -h - display this message"
  echo " -m email_address - send results to email_address"

  exit
}


EMAIL=
fopt=
FORCE_UNLOCK=
while getopts 'fhm:' OPTION
do
case $OPTION  in
  f)
   fopt="-f"
   FORCE_UNLOCK=1
   ;;
  h)
   USAGE
   exit
   ;;
  m)
   EMAIL="$OPTARG"
   ;;
esac
done
shift $(($OPTIND-1))

LOCK_FILE=$HOME/.clusterbot/lockfile
if [[ "$FORCE_UNLOCK" == "" ]] && [[ -e $LOCK_FILE ]]; then
  echo "***error: another instance of sshbot.sh is running"
  echo "          If this is not the case, rerun using the -f option"
  exit
fi
rm -f $LOCK_FILE

CURDIR=`pwd`

BINDIR=$CURDIR/`dirname "$0"`
cd $BINDIR
BINDIR=`pwd`
cd $CURDIR

if [ ! -d $HOME/.clusterbot ]; then
  mkdir $HOME/.clusterbot
fi
OUTPUT=$HOME/.clusterbot/sshbot.out

cd $BINDIR

not_have_git=`git describe --dirty --long |& grep fatal | wc -l`
if [ "$not_have_git" == "0" ]; then
  echo updating bot repo
  git fetch origin        &> /dev/null
  git merge origin/master &> /dev/null
fi

./sshbot.sh $fopt | tee  $OUTPUT

nerrors=`grep ***Error $OUTPUT | wc -l`
nwarnings=`grep ***Warning $OUTPUT | wc -l`
if [ "$EMAIL" != "" ]; then
  echo emailing results to $EMAIL
  cat $OUTPUT | mail -s "ssh status: $nerrors Errrors, $nwarnings Warnings" $EMAIL
fi

cd $CURDIR
