#!/bin/bash

# The Firebot script is part of an automated continuous integration system.
# Consult the FDS Config Management Plan for more information.

#---------------------------------------------
#                   usage
#---------------------------------------------

function usage {
echo "Verification and validation testing script for FDS"
echo ""
echo "Example usage:"
echo "./run_firebot.sh - runs firebot using your existing repos and branches"
echo "./run_firebot.sh -C - runs firebot after cloning repos.  This option should"
echo "                      NEVER be run in repos where you do your normal work"
echo "More options:"
echo "-C - clone repos (same as -R master)"
echo "-f - force firebot run"
echo "-h - display this message"
echo "-k - kill currently running firebot and all processes and jobs it started"
echo "-m email_address - email firebot results to email_address"
echo "-q queue - specify queue [default: $QUEUE]"
echo "-R branch_name - clone repos using branch :branch_name "
echo "-y - answer yes when asked to proceed (used when running from crontab)"

echo "Upload Options:"
echo "-o owner - specify the github relase owner when uploading manuals. [default: $GH_OWNER]"
echo "-r repo - specify the github repo name when uploading manuals. [default: $GH_REPO]"
echo "-U - upload guides (only by user firebot)"
echo "-w webdir - copy firebot web summary the directory webdir under the web root (default: $WEB_ROOT/webdir)"
echo "-W webroot - root web directory [default: $WEB_ROOT]"
exit 0
}

#---------------------------------------------
#                   LIST_DESCENDANTS
#---------------------------------------------

LIST_DESCENDANTS ()
{
#  local children=$(ps -o pid= --ppid "$1")
  local children=$(pgrep -P $1)

  for pid in $children
  do
    LIST_DESCENDANTS $pid
  done

  echo "$children"
}

#VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
#                             beginning of run_firebot.sh
#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

#*** location of firebot processor id

mkdir -p ~/.firebot
firebot_pid=~/.firebot/firesmokebot_pid

CURDIR=`pwd`

#*** make sure firebot is started in the right location

if [ -e .fds_git ]; then
  cd ../..
  repo=`pwd`
  cd $CURDIR
else
  echo "***error: firebot not running in the bot/Firebot directory"
  exit 1
fi
if [ "$FIREMODELS" != "" ]; then
  export FIREMODELS=$repo
fi

echo $0 $* > command.firebot

if [ "`uname`" == "Darwin" ] ; then
  echo "***error: Mac not supported"
  exit
fi

cd $CURDIR
BOTREVBRANCH=`./GetRevBranch.sh bot`
EXPREVBRANCH=`./GetRevBranch.sh exp`
FDSREVBRANCH=`./GetRevBranch.sh fds`
FIGREVBRANCH=`./GetRevBranch.sh fig`
FDSREVBRANCH=`./GetRevBranch.sh fds`
OUTREVBRANCH=`./GetRevBranch.sh out`
SMVREVBRANCH=`./GetRevBranch.sh smv`

cd $CURDIR

#*** define initial values

BRANCH=current
UPLOADGUIDES=
FORCE=
KILL_FIREBOT=
export PREFIX=FB_
CLONE_REPOS=
CLONE_REPOS_ARG=
WEB_DIR=
WEB_ROOT=/opt/www/html
CLONEFILE=
PROCEED=

#*** checking to see if a queing system is available
notfound=`sinfo 2>&1 | tail -1 | grep "not found" | wc -l`
if [ $notfound -eq 1 ] ; then
  echo "***error: sinfo coommand not found"
  exit
fi
QUEUE=`sinfo -ho "%P" | grep *$ | sed -e 's/[*]$//'`


#*** parse command line options

while getopts 'Cfhkm:o:q:r:R:Uw:W:y' OPTION
do
case $OPTION  in
  C)
   CLONE_REPOS=master
   BRANCH=current
   ;;
  f)
   FORCE=1
   ;;
  h)
   usage;
   ;;
  k)
   KILL_FIREBOT="1"
   ;;
  m)
   EMAIL="$OPTARG"
   ;;
  o)
   export GH_OWNER="$OPTARG"
   ;;
  q)
   QUEUE="$OPTARG"
   ;;
  r)
   export GH_REPO="$OPTARG"
   ;;
  R)
   CLONE_REPOS="$OPTARG"
   BRANCH=current
   ;;
  U)
   UPLOADGUIDES=-U
   ;;
  w)
   WEB_DIR="$OPTARG"
   ;;
  W)
   WEB_ROOT="$OPTARG"
   ;;
  y)
   PROCEED=1
   ;;
  \?)
  echo "***error: unknown option entered. aborting firebot"
  exit 1
  ;;
esac
done
shift $(($OPTIND-1))

CLONE_REPOS_ARG=$CLONE_REPOS

if [ "$WEB_DIR" == "" ]; then
  WEB_ROOT=
fi
if [ "$WEB_ROOT" == "" ]; then
  WEB_DIR=
fi
if [ "$WEB_DIR" != "" ]; then
  WEB_DIR="-w $WEB_DIR"
fi
if [ "$WEB_ROOT" != "" ]; then
  WEB_ROOT="-W $WEB_ROOT"
fi

if [ "$CLONE_REPOS" != "" ]; then
  CLONE_REPOS="-R $CLONE_REPOS"
fi

#*** kill firebot

if [ "$KILL_FIREBOT" == "1" ]; then
  if [ -e $firebot_pid ] ; then
    PID=`head -1 $firebot_pid`

    JOBS=$(LIST_DESCENDANTS $PID)
    if [ "$JOBS" != "" ]; then
      echo killing processes invoked by firebot: $JOBS
      kill -9 $JOBS
    fi

    JOBIDS=`squeue | grep $PREFIX | awk -v user="$USER" '{if($4==user){print $1}}' | awk -F'.' '{print $1}'`
    if [ "$JOBIDS" != "" ]; then
      echo killing firebot jobs with Id:$JOBIDS
      qdel $JOBIDS
    fi

    echo "killing firebot (PID=$PID)"
    kill -9 $PID
    echo firebot process $PID killed
    rm -f $firebot_pid
  else
    echo firebot is not running
  fi
  exit 0
fi

#*** abort if firebot is already running

if [[ -e $firebot_pid ]] && [[ "$FORCE" == "" ]] ; then
  echo Firebot or smokebot are already running. If this
  echo "is not the case re-run using the -f option."
  exit 1
fi

if [[ "$EMAIL" != "" ]]; then
  EMAIL="-m $EMAIL"
fi

cd $CURDIR

echo ""
echo "Firebot Properties"
echo "------------------"
  echo "       Queue: $QUEUE"
if [ "$BOTBRANCH" != "" ]; then
  echo "  bot branch: $BOTBRANCH"
fi

if [ "$FDS_HASH" != "" ]; then
  echo "    fds hash: $FDS_HASH"
fi
if [ "$FDS_REVISION" != "" ]; then
  echo "fds revision: $FDS_REVISION"
fi

if [ "$SMV_HASH" != "" ]; then
  echo "    smv hash: $SMV_HASH"
fi
if [ "$SMV_REVISION" != "" ]; then
  echo "smv revision: $SMV_REVISION"
fi

if [ "$CLONE_REPOS" != "" ]; then
  echo "       Cloning repos: fds, exp, fig, out and smv using branch $CLONE_REPOS_ARG"
fi
if [ "$CLONE_REPOS" == "" ]; then
  echo "  exp rev/branch: $EXPREVBRANCH"
  echo "  fds rev/branch: $FDSREVBRANCH"
  echo "  fig rev/branch: $FIGREVBRANCH"
  echo "  out rev/branch: $OUTREVBRANCH"
  echo "  smv rev/branch: $SMVREVBRANCH"
fi

if [ "$PROCEED" == "" ]; then
  echo "Do you wish to continue?"
  echo "Press any key to continue or <CTRL c> to cancel"
  echo "Use the -y option to avoid this message"
  read val
fi
echo continuing

BRANCH="-b $BRANCH"
QUEUE="-q $QUEUE"

touch $firebot_pid
firebot_status=0
./firebot.sh -p $firebot_pid $BRANCH $UPLOADGUIDES $QUEUE $CLONE_REPOS $CLONEFILE $EMAIL $WEB_ROOT $WEB_DIR "$@"
firebot_status=$?
rm -f $firebot_pid
exit $firebot_status
