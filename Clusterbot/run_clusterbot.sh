#!/bin/bash

#---------------------------------------------
# ---------------------------- USAGE ----------------------------------
#---------------------------------------------

function USAGE {
  echo "Usage: run_smokebot.sh [options]"
  echo ""
  echo "run_clusterbot.sh - perform various checks to verify a Linux cluster is working properly. If the -q option"
  echo "                is specified, run test cases on multiple nodes. The test cases are very simple designed"
  echo "                only to verify that communication works between processes.  To run more realistic test"
  echo "                cases, use firebot or smokebot."
  echo ""
  echo "Options:"
  echo " -f - override lock to force clusterbot run"
  echo " -h - display this message"
  echo " -m email_address - send results to email_address"
  echo " -n n - run n cases on each queue [default: $NCASES_PER_QUEUE]"
  echo " -q q - run test cases using the queue q."
  echo " -Q q - same as the -q option except that only test cases are run."
  echo "         Other tests are not performed."
  echo " -r - check file contents readable only by root.  If this option is not"
  echo "      used, only the file size and modification date are checked.  You"
  echo "      need to have sudo priviledges to use this option."

  exit
}


EMAIL=
fopt=
nopt=
QOPT=
qopt=
ropt=
FORCE_UNLOCK=
while getopts 'fhm:n:q:Q:r' OPTION
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
  n)
   NCASES="$OPTARG"
   re='^[0-9]+$'
   if ! [[ $NCASES =~ $re ]] ; then
     echo "***error: -n $NCASES not a number"
     exit
   fi
   NCASES_PER_QUEUE=$NCASES
   nopt="-n $NCASES_PER_QUEUE"
   ;;
  Q)
   QOPT="-Q $OPTARG"
   ;;
  q)
   qopt="-q $OPTARG"
   ;;
  r)
   ropt="-r"
   ;;
esac
done
shift $(($OPTIND-1))

LOCK_FILE=$HOME/.clusterbot/lockfile
if [[ "$FORCE_UNLOCK" == "" ]] && [[ -e $LOCK_FILE ]]; then
  echo "***error: another instance of clusterbot.sh is running"
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
OUTPUT=$HOME/.clusterbot/clusterbot.out
LOGFILE=$HOME/.clusterbot/clusterbot.log

cd $BINDIR

not_have_git=`git describe --dirty --long |& grep fatal | wc -l`
if [ "$not_have_git" == "0" ]; then
  echo updating bot repo
  git fetch origin        &> /dev/null
  git merge origin/master &> /dev/null
fi

./clusterbot.sh $fopt $nopt $QOPT $qopt $ropt | tee  $OUTPUT

nerrors=`grep ***Error $OUTPUT | wc -l`
nwarnings=`grep ***Warning $OUTPUT | wc -l`
if [ ! -e $LOGFILE ]; then
 cp $OUTPUT $LOGFILE
fi 

LOGDATE=`cat $LOGFILE | awk '{print $6" "$7" "$8}'`
LOGFILE2=/tmp/logfile.$$
OUTPUT2=/tmp/output.$$
tail -n +2 $LOGFILE > $LOGFILE2
tail -n +2 $OUTPUT > $OUTPUT2

nlogdiff=`diff $LOGFILE2 $OUTPUT2 | wc -l`
if [ $nlogdiff -gt 0 ]; then
 cp $OUTPUT $LOGFILE
fi

rm -f $LOGILE2 $OUTPUT2


echo ""
if [ $nlogdiff -eq 0 ]; then
  echo "$CB_HOSTS status since $LOGDATE: $nerrors Errors, $nwarnings Warnings"
else
  echo "$CB_HOSTS status has changed: $nerrors Errors, $nwarnings Warnings"
fi
if [ "$EMAIL" != "" ]; then
  echo emailing results to $EMAIL
  if [ $nlogdiff -eq 0 ]; then
    cat $OUTPUT | mail -s "$CB_HOSTS status since $LOGDATE: $nerrors Errors, $nwarnings Warnings" $EMAIL
  else
    cat $OUTPUT | mail -s "$CB_HOSTS status has changed: $nerrors Errors, $nwarnings Warnings" $EMAIL
  fi
fi

cd $CURDIR
