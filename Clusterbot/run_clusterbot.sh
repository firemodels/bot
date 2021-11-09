#!/bin/bash

#---------------------------------------------
# ---------------------------- USAGE ----------------------------------
#---------------------------------------------

function USAGE {
  echo "Usage: clusterbot.sh "
  echo ""
  echo "clusterbot.sh - perform various checks on a Linux cluster"
  echo ""
  echo " -h - display this message"
  echo "Usage: clusterbot.sh "
  echo ""
  echo "clusterbot.sh - perform various checks to verify a Linux cluster is working properly. If the -q option"
  echo "                is specified, run test cases on multiple nodes. The test cases are very simple designed"
  echo "                only to verify that communication works between processes.  To run more realistic test"
  echo "                cases, use firebot or smokebot."
  echo ""
  echo " -f - override lock to force clusterbot run"
  echo " -h - display this message"
  echo " -m email_address - send results to email_address"
  echo " -n n - run n cases on each queue [default: $NCASES_PER_QUEUE]"
  echo " -q q - run test cases using the queue q."
  echo " -Q q - same as the -q option except that only test cases are run."
  echo "         Other tests are not performed."
  exit
}


EMAIL=
fopt=
nopt=
QOPT=
qopt=
FORCE_UNLOCK=
while getopts 'fhm:n:q:Q:' OPTION
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

cd $BINDIR

echo updating bot repo
git fetch origin        &> /dev/null
git merge origin/master &> /dev/null

./clusterbot.sh $fopt $nopt $QOPT $qopt | tee  $OUTPUT

nerrors=`grep ***Error $OUTPUT | wc -l`
nwarnings=`grep ***Warning $OUTPUT | wc -l`
if [ "$EMAIL" != "" ]; then
  echo emailing results to $EMAIL
  cat $OUTPUT | mail -s "$CB_HOSTS status: $nerrors Errrors, $nwarnings Warnings" $EMAIL
fi

cd $CURDIR
