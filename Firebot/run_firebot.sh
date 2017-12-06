#!/bin/bash

# The Firebot script is part of an automated continuous integration system.
# Consult the FDS Config Management Plan for more information.

#---------------------------------------------
#                   usage_all
#---------------------------------------------

function usage_all {
echo "Verification and validation testing script for FDS"
echo ""
echo "Options:"
#echo "-b - branch_name - run firebot using branch_name [default: $BRANCH]"
echo "-B  - use startup files to set the environment, not modules"
echo "-c - clean repo"
echo "-h - display most commonly used options"
echo "-H - display all options"
echo "-k - kill firebot if it is running"
echo "-q queue - specify queue [default: $QUEUE]"
echo "-u - update repos"
echo "-v - show options used to run firebot"
#echo "validationbot mode:"
#echo "-C - commit validationbot output results"
#echo "-D caselist - specify file containing list of validationbot cases"
#echo "-K - kill validationbot if it is running"
#echo "-P - commit and push (to github repo) validationbot output results (not implemented)"
#echo "-S - show list validationbot cases"
#echo "-V n - run firebot in validationbot mode with specified number (n) of processes"
echo "Miscellaneous:"
echo "-i - use installed version of smokeview"
echo "-I - use development version of fds"
echo "-J - use Intel MPI version fds"
echo "-f - force firebot run"
echo "-F - skip figure generation and build document stages"
echo "-L - firebot lite,  run only stages that build a debug fds and run cases with it"
echo "                    (no release fds, no release cases, no matlab, etc)"
if [ "$EMAIL" != "" ]; then
  echo "-m email_address [default: $EMAIL]"
else
  echo "-m email_address "
fi
echo "-s - skip matlab and build document stages"
echo "-U - upload guides (only by user firebot)"
exit
}


#---------------------------------------------
#                   usage
#---------------------------------------------

function usage {
echo "Verification and validation testing script for FDS"
echo ""
echo "Options:"
echo "-c - clean repos"
echo "-h - display most commonly used options"
echo "-H - display all options"
echo "-k - kill firebot if it is running"
echo "-u - update repos"
echo "-v - show options used to run firebot"
exit
}

#---------------------------------------------
#                   CHK_REPO
#---------------------------------------------

CHK_REPO ()
{
  local repodir=$1

  if [ ! -e $repodir ]; then
     echo "***error: the repo directory $repodir does not exist."
     echo "          Aborting firebot."
     return 1
  fi
  return 0
}

#---------------------------------------------
#                   CD_REPO
#---------------------------------------------

CD_REPO ()
{
  local repodir=$1
  local branch=$2

  CHK_REPO $repodir || return 1

  cd $repodir
  if [ "$branch" != "" ]; then
     CURRENT_BRANCH=`git rev-parse --abbrev-ref HEAD`
     if [ "$CURRENT_BRANCH" != "$branch" ]; then
       echo "***error: was expecting branch $branch in repo $repodir."
       echo "Found branch $CURRENT_BRANCH. Aborting firebot."
       return 1
     fi
  fi
  return 0
}

#---------------------------------------------
#                   LIST_DESCENDANTS
#---------------------------------------------

LIST_DESCENDANTS ()
{
  local children=$(ps -o pid= --ppid "$1")

  for pid in $children
  do
    LIST_DESCENDANTS "$pid"
  done

  echo "$children"
}

#VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
#                             Primary script execution =
#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

if [ ! -d ~/.fdssmvgit ] ; then
  mkdir ~/.fdssmvgit
fi
firebot_pid=~/.fdssmvgit/firebot_pid

CURDIR=`pwd`

if [ -e .fds_git ]; then
  cd ../..
  repo=`pwd`
  cd $CURDIR
else
  echo "***error: firebot not running in the bot/Firebot directory"
  exit
fi

# checking to see if a queing system is available
QUEUE=firebot
notfound=`qstat -a 2>&1 | tail -1 | grep "not found" | wc -l`
if [ $notfound -eq 1 ] ; then
  QUEUE=none
fi

platform="linux"
if [ "`uname`" == "Darwin" ] ; then
  platform="osx"
fi

USEINSTALL=
BRANCH=master
botscript=firebot.sh
UPDATEREPO=
CLEANREPO=0
UPDATE=
CLEAN=
RUNFIREBOT=1
UPLOADGUIDES=
FORCE=
SKIPMATLAB=
SKIPFIGURES=
FIREBOT_LITE=
KILL_FIREBOT=
PREFIX=FB_
ECHO=
MAX_VALIDATION_PROCESSES=
commit=
push=
caselistfile=""
showcaselist=
debug_mode=
DV=
INTEL=
export QFDS_STARTUP=

while getopts 'b:BcdCD:FfHhIiJKkLm:Pq:nsSuUvV:' OPTION
do
case $OPTION  in
  b)
#   BRANCH="$OPTARG"
    echo "***Warning: -b option for specifying a branch is not supported at this time"
   ;;
  B)
    export QFDS_STARTUP=1
   ;;
  c)
   CLEANREPO=1
   ;;
  C)
   commit=-C
   ;;
  d)
    debug_mode="-d "
   ;;
  D)
    caselistfile="-D $OPTARG"
   ;;
  f)
   FORCE=1
   ;;
  F)
   SKIPFIGURES=-F
   ;;
  h)
   usage;
   ;;
  H)
   usage_all;
   ;;
  i)
   USEINSTALL="-i"
   ;;
  I)
   DV="-I"
   ;;
  J)
   INTEL="-J"
   ;;
  k)
   KILL_FIREBOT="1"
   ;;
  K)
   KILL_FIREBOT="1"
   PREFIX=VB_
   ;;
  L)
   FIREBOT_LITE=-L
   ;;
  m)
   EMAIL="$OPTARG"
   ;;
  q)
   QUEUE="$OPTARG"
   ;;
  n)
   UPDATEREPO=0
   ;;
  P)
   push=-P
   ;;
  s)
   SKIPMATLAB=-s
   ;;
  S)
   showcaselist="-S"
   ;;
  u)
   UPDATEREPO=1
   ;;
  U)
   UPLOADGUIDES=-U
   ;;
  v)
   RUNFIREBOT=0
   ECHO=echo
   ;;
  V)
   MAX_VALIDATION_PROCESSES="-V $OPTARG"
   ;;
esac
done
shift $(($OPTIND-1))

if [ "$KILL_FIREBOT" == "1" ]; then
  if [ -e $firebot_pid ] ; then
    PID=`head -1 $firebot_pid`
    if [ "$platform" == "linux" ]; then
      echo killing process invoked by firebot
      kill -9 $(LIST_DESCENDANTS $PID)
    fi
    echo "killing firebot (PID=$PID)"
    kill -9 $PID
    if [ "$QUEUE" != "none" ]; then
      JOBIDS=`qstat -a | grep $PREFIX | awk -v user="$USER" '{if($2==user){print $1}}' | awk -F'.' '{print $1}'`
      if [ "$JOBIDS" != "" ]; then
        echo killing firebot jobs with Id:$JOBIDS
        qdel $JOBIDS
      fi
    fi
    echo firebot process $PID killed
  else
    echo firebot is not running, cannot be killed.
  fi
  exit
fi
if [ -e $firebot_pid ] ; then
  if [ "$FORCE" == "" ] ; then
    echo Firebot or smokebot are already running. If this
    echo "is not the case re-run using the -f option."
    exit
  fi
fi
if [[ "$EMAIL" != "" ]]; then
  EMAIL="-m $EMAIL"
fi

# for now always assume the bot repo is always in the master branch
# and that the -b branch option only apples to the fds and smv repos

if [[ "$UPDATEREPO" == "1" ]]; then
   UPDATE=-u
   if [[ "$RUNFIREBOT" == "1" ]]; then
     CD_REPO $repo/bot/Firebot master || exit 1
     
     git fetch origin &> /dev/null
     git merge origin/master &> /dev/null
     cd $CURDIR
  fi
fi
if [[ "$CLEANREPO" == "1" ]]; then
  CLEAN=-c
fi
BRANCH="-b $BRANCH"
QUEUE="-q $QUEUE"
touch $firebot_pid
$ECHO  ./$botscript -p $firebot_pid $commit $push $UPDATE $DV $INTEL $debug_mode $showcaselist $caselistfile $MAX_VALIDATION_PROCESSES $FIREBOT_LITE $USEINSTALL $UPLOADGUIDES $CLEAN $QUEUE $SKIPMATLAB $SKIPFIGURES $EMAIL "$@"
if [ -e $firebot_pid ]; then
  rm $firebot_pid
fi
