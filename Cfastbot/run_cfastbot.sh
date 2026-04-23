#!/bin/bash
EMAIL_LIST="$HOME/.cfastbot/cfastbot_email_list.sh"

# CFASTbot
# This script runs the CFAST verification/validation suite 

#---------------------------------------------
#                   usage
#---------------------------------------------

function usage {
echo ""
echo "Verification and validation testing script for cfast"
echo ""
echo "Options:"
echo "-f - force cfastbot run"
echo "-h - display this message"
echo "-k - kill cfastbot"
echo "-m email -  email_address "
echo "-q queue_name - run cases using the queue queue_name (default: $QUEUE)"
echo ""
ehco "Less commonly used options:"
echo "-a - run automatically if cfast repo has changed"
echo "-C - clone cfast, exp, fds and smv repos"
echo "-F config.sh  - clone repos using revision and tags in config.sh"
echo "-o - specify GH_OWNER when uploading manuals. [default: $GH_OWNER]"
echo "-r - specify GH_REPO when uploading manuals. [default: $GH_REPO]"
echo "-U - upload guide (only if authenticated at gitub)"
exit
}

#---------------------------------------------
#                   LIST_DESCENDANTS
#---------------------------------------------

#*** used to kill cfastbot and all scripts cfastbot has called
LIST_DESCENDANTS ()
{
  local children=$(ps -o pid= --ppid "$1")

  for pid in $children
  do
    LIST_DESCENDANTS "$pid"
  done

  echo "$children"
}

#VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
#                             start of script
#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

mkdir -p ~/.cfastbot
cfastbot_pid=~/.cfastbot/cfastbot_pid

CURDIR=`pwd`
QUEUE=$(sinfo -h -o "%P" | grep '\*' | sed 's/\*//')

if [ ! -e .cfast_git ]; then
  echo "***error: cfastbot not running in the bot/Cfastbot directory"
  exit
fi

cd ../..
reporoot=`pwd`
cd $CURDIR

botrepo=$reporoot/bot
CLONEREPOS=
CONFIG=
EMAIL=
FORCE=
KILL_CFASTBOT=
RUNAUTO=
UPLOAD=

#*** parse command line options
while getopts 'aCfF:hikm:o:q:r:U' OPTION
do
case $OPTION  in
  a)
   RUNAUTO=-a
   ;;
  C)
   CLONEREPOS=-C
   CONFIG=
   ;;
  f)
   FORCE=1
   ;;
  F)
   CONFIG="$OPTARG"
   CLONEREPOS=
   if [ ! -e $CONFIG ]; then
     echo ***error: configuration file $CONFIG does not exist
     exit
   fi
   CONFIG="-F $CONFIG"
   ;;
  h)
   usage;
   ;;
  k)
   KILL_CFASTBOT="1"
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
  U)
   UPLOAD=-U
   ;;
esac
done
shift $(($OPTIND-1))

#*** kill cfastbot if requested
if [ "$KILL_CFASTBOT" == "1" ]; then
  if [ -e $cfastbot_pid ] ; then
    PID=`head -1 $cfastbot_pid`
    echo killing process invoked by cfastbot
    kill -9 $(LIST_DESCENDANTS $PID)
    echo "killing cfastbot (PID=$PID)"
    kill -9 $PID
    JOBIDS=`squeue | grep cb_ | awk -v user="$USER" '{if($2==user){print $1}}'`
    if [ "$JOBIDS" != "" ]; then
      echo killing cfastbot jobs with Id:$JOBIDS
      qdel $JOBIDS
    fi
    echo cfastbot process $PID killed
  else
    echo cfastbot is not running, cannot be killed.
  fi
  exit
fi

#*** make sure another instance of cfastbot is not running
if [[ -e $cfastbot_pid ]] && [[ "$FORCE" == "" ]]; then
  echo cfastbot is already running. If this is
  echo not the case rerun using the -f option.
  if [[ "$RUNAUTO" == "" ]] && [[ -e $EMAIL_LIST ]]; then
    source $EMAIL_LIST
    echo "Cfastbot was unable to start.  Another instance was already running or it did not complete successfully"  | mail -s "error: cfastbot failed to start" $mailTo > /dev/null
  fi
  exit
fi

touch $cfastbot_pid
if [[ "$EMAIL" != "" ]]; then
  EMAIL="-m $EMAIL"
fi

REPO="-r $reporoot"
QUEUE="-q $QUEUE"
PID="-p $cfastbot_pid"
cd $CURDIR
echo   ./cfastbot.sh $PID $REPO $CLONEREPOS $RUNAUTO $CONFIG $QUEUE $UPLOAD $EMAIL "$@"
       ./cfastbot.sh $PID $REPO $CLONEREPOS $RUNAUTO $CONFIG $QUEUE $UPLOAD $EMAIL "$@"
rm -f $cfastbot_pid
