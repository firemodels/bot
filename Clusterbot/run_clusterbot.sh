#!/bin/bash

EMAIL=$SMV_EMAIL
fopt=
Fopt=
nopt=
QOPT=
qopt=
ropt=
FORCE_UNLOCK=
NCASES_PER_QUEUE=20
while getopts 'fFhm:n:q:Q:r' OPTION
do
case $OPTION  in
  f)
   fopt="-f"
   FORCE_UNLOCK=1
   ;;
  F)
   Fopt="-F"
   ;;
  h)
   ./clusterbot_usage.sh run_clusterbot.sh $NCASES_PER_QUEUE 1
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
   
nopt="-n $NCASES_PER_QUEUE"

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
ERRORS=$HOME/.clusterbot/clusterbot.err
HEADER=$HOME/.clusterbot/clusterbot.hdr
LOGFILE=$HOME/.clusterbot/clusterbot.log
rm -f $OUTPUT

cd $BINDIR

not_have_git=`git describe --dirty --long |& grep fatal | wc -l`
if [ "$not_have_git" == "0" ]; then
  echo updating bot repo
  git fetch origin        &> /dev/null
  git merge origin/master &> /dev/null
fi

echo > $OUTPUT
START_TIME=`date`
./clusterbot.sh $fopt $Fopt $nopt $QOPT $qopt $ropt | tee  $OUTPUT
STOP_TIME=`date`

nerrors=`grep ***Error     $OUTPUT | wc -l`
nwarnings=`grep ***Warning $OUTPUT | wc -l`

echo "" > $ERRORS

echo "-----------------------------------------------------"    >  $HEADER
echo "start: $START_TIME"                                       >> $HEADER
echo " stop: $STOP_TIME"                                        >> $HEADER

if [ $nerrors -gt 0 ]; then
  echo "--------------------- Errors ------------------------"  >> $ERRORS
  grep ***Error $OUTPUT                                         >> $ERRORS
  echo "-----------------------------------------------------"  >> $ERRORS
fi
if [ $nwarnings -gt 0 ]; then
  echo "--------------------- Warnings ----------------------"  >> $ERRORS
  grep ***Warning $OUTPUT                                       >> $ERRORS
  echo "-----------------------------------------------------"  >> $ERRORS
fi

if [ ! -e $LOGFILE ]; then
 cp $ERRORS $LOGFILE
fi 

LOGDATE=`ls -l $LOGFILE | awk '{print $6" "$7" "$8}'`

nlogdiff=`diff $LOGFILE $ERRORS | wc -l`
if [ $nlogdiff -gt 0 ]; then
 cp $ERRORS $LOGFILE
fi

echo ""
if [ $nlogdiff -eq 0 ]; then
  echo "$CB_HOSTS status since $LOGDATE: $nerrors Errors, $nwarnings Warnings"
else
  echo "$CB_HOSTS status has changed: $nerrors Errors, $nwarnings Warnings"
fi
cat $HEADER $ERRORS 
if [ "$EMAIL" != "" ]; then
  echo emailing results to $EMAIL
  if [ $nlogdiff -eq 0 ]; then
    cat $HEADER $ERRORS $OUTPUT | mail -s "$CB_HOSTS status since $LOGDATE: $nerrors Errors, $nwarnings Warnings" $EMAIL
  else
    cat $HEADER $ERRORS $OUTPUT | mail -s "$CB_HOSTS status has changed: $nerrors Errors, $nwarnings Warnings" $EMAIL
  fi
fi

cd $CURDIR
