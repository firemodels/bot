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
  echo " -u - update bot repo then exit"

  exit
}


EMAIL=
fopt=
UPDATE=
while getopts 'fhm:u' OPTION
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
  u)
   UPDATE=1
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
LOGFILE=$HOME/.clusterbot/sshbot.log

cd $BINDIR

WHOAMI=`whoami`
if [ "$WHOAMI" != "root" ]; then
  not_have_git=`git describe --dirty --long |& grep fatal | wc -l`
  if [ "$not_have_git" == "0" ]; then
    echo updating bot repo
    git fetch origin        &> /dev/null
    git merge origin/master &> /dev/null
  fi
fi
if [ "$UPDATE" != "" ]; then
  exit
fi

./sshbot.sh $fopt | tee  $OUTPUT

if [ ! -e $LOGFILE ]; then
 cp $OUTPUT $LOGFILE
fi

LOGDATE=`ls -l $LOGFILE | awk '{print $6" "$7" "$8}'`
LOGFILE2=/tmp/logfile.$$
OUTPUT2=/tmp/output.$$
tail -n +2 $LOGFILE > $LOGFILE2
tail -n +2 $OUTPUT > $OUTPUT2

nlogdiff=`diff $LOGFILE2 $OUTPUT2 | wc -l`
if [ $nlogdiff -gt 0 ]; then
 cp $OUTPUT $LOGFILE
fi

rm -f $LOGILE2 $OUTPUT2

nerrors=`grep ***Error $OUTPUT | wc -l`
nwarnings=`grep ***Warning $OUTPUT | wc -l`
echo ""
if [ $nlogdiff -eq 0 ]; then
  echo "ssh status since $LOGDATE: $nerrors Errors"
else
  echo "ssh status has changed: $nerrors Errors"
fi
if [ "$EMAIL" != "" ]; then
  if [ $nlogdiff -eq 0 ]; then
    cat $OUTPUT | mail -s "ssh status since $LOGDATE: $nerrors Errors" $EMAIL
  else
    cat $OUTPUT | mail -s "ssh status has changed since $LOGDATE: $nerrors Errors" $EMAIL
  fi
fi

cd $CURDIR
