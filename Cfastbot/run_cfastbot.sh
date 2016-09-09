#!/bin/bash

if [ ! -d ~/.cfastgit ] ; then
  mkdir ~/.cfastgit
fi
cfastbot_pid=~/.cfastgit/cfastbot_pid

CURDIR=`pwd`

# checking to see if a queing system is available
QUEUE=smokebot
notfound=`qstat -a 2>&1 | tail -1 | grep "not found" | wc -l`
if [ $notfound -eq 1 ] ; then
  QUEUE=none
fi

if [ -e .cfast_git ]; then
  cd ../..
  reponame=`pwd`
  cd $CURDIR
else
  echo "***error: cfastbot not running in the Firemodels repo"
  exit
fi

function usage {
echo "Verification and validation testing script for cfast"
echo ""
echo "Options:"
echo "-a - run automatically if cfast repo has changed"
echo "-c - clean cfast and FDS-SMV repos"
echo "-f - force cfastbot run"
echo "-h - display this message"
echo "-i - use installed smokeview and background (if using the 'none' queue)"
echo "-I - compiler [ default: $compiler]"
echo "-k - kill cfastbot"
echo "-m email -  email_address "
echo "-q queue_name - run cases using the queue queue_name"
echo "     default: $QUEUE"
echo "-s - skip matlab and guide generating stages"
echo "-u - update cfast and FDS-SMV repos"
echo "-U - upload guide (only by user: cfastbot)"
echo "-v - show options used to run cfastbot"
exit
}

LIST_DESCENDANTS ()
{
  local children=$(ps -o pid= --ppid "$1")

  for pid in $children
  do
    LIST_DESCENDANTS "$pid"
  done

  echo "$children"
}

RUNAUTO=
UPDATEREPO=
CLEANREPO=0
RUNCFASTBOT=1
EMAIL=
FORCE=
compiler=intel

MATLABEXE=
SKIP=
havematlab=`which matlab 2> /dev/null | wc -l`

UPLOAD=
USEINSTALL=
KILL_CFASTBOT=

while getopts 'acfhiI:km:q:suUv' OPTION
do
case $OPTION  in
  a)
   RUNAUTO=-a
   ;;
  c)
   CLEANREPO=1
   ;;
  f)
   FORCE=1
   ;;
  h)
   usage;
   ;;
  i)
   USEINSTALL="-i"
   ;;
  I)
   compiler="$OPTARG"
   ;;
  k)
   KILL_CFASTBOT="1"
   ;;
  m)
   EMAIL="$OPTARG"
   ;;
  M)
   MATLABEXE="-M"
   ;;
  q)
   QUEUE="$OPTARG"
   ;;
  s)
   SKIP="-s"
   ;;
  u)
   UPDATEREPO=1
   ;;
  U)
   UPLOAD=-U
   ;;
  v)
   RUNCFASTBOT=0
   ;;
esac
done
shift $(($OPTIND-1))

if [ "$KILL_CFASTBOT" == "1" ]; then
  if [ -e $cfastbot_pid ] ; then
    PID=`head -1 $cfastbot_pid`
    echo killing process invoked by cfastbot
    kill -9 $(LIST_DESCENDANTS $PID)
    echo "killing cfastbot (PID=$PID)"
    kill -9 $PID
    JOBIDS=`qstat -a | grep CB_ | awk -v user="$USER" '{if($2==user){print $1}}'`
    if [ "$JOBIDS" != "" ]; then
      echo killing cfastbot jobs with Id:$JOBIDS
      qdel $JOBIDS
    fi
    echo cfastbot process $PID killed
    if [ -e $cfastbot_pid ]; then
      rm $cfastbot_pid
    fi
  else
    echo cfastbot is not running, cannot be killed.
  fi
  exit
fi


if [ -e $cfastbot_pid ] ; then
  if [ "$FORCE" == "" ]; then
    echo cfastbot is already running. If this is
    echo not the case rerun using the -f option.
    exit
  fi
fi
touch $cfastbot_pid
if [[ "$EMAIL" != "" ]]; then
  EMAIL="-m $EMAIL"
fi
if [[ "$UPDATEREPO" == "1" ]]; then
   UPDATEREPO=-u
   if [ "$RUNCFASTBOT" == "1" ]; then
     cd $reponame/bot
     git remote update
     git checkout master
     git merge origin/master
  fi
fi
if [[ "$CLEANREPO" == "1" ]]; then
  CLEAN=-c
fi

if [ $havematlab -eq 0 ]; then
   MATLABEXE=-M
fi
if [ "$SKIP" != "" ]; then
   MATLAB=
fi

REPO="-r $reponame"
QUEUE="-q $QUEUE"
compiler="-I $compiler"
PID="-p $cfastbot_pid"
cd $CURDIR
if [ "$RUNCFASTBOT" == "1" ] ; then
  ./cfastbot.sh $PID $REPO $USEINSTALL $RUNAUTO $compiler $UPDATEREPO $CLEAN $QUEUE $SKIP $MATLABEXE $UPLOAD $EMAIL "$@"
else
  echo ./$botscript $PID $REPO $USEINSTALL $RUNAUTO $compiler $UPDATEREPO $CLEAN $QUEUE $SKIP $MATLABEXE $UPLOAD $EMAIL "$@"
fi
rm $cfastbot_pid
