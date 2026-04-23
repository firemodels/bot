#!/bin/bash
EMAIL_LIST="$HOME/.cfastbot/cfastbot_email_list.sh"

# CFASTbot
# This script runs the CFAST verification/validation suite 
# on the latest revision of the repository.

#---------------------------------------------
#                   CHK_REPO
#---------------------------------------------

CHK_REPO ()
{
  local repodir=$1
  
  if [ ! -e $repodir ]; then
     echo "***error: the repo directory $repodir does not exist."
     echo "          Aborting cfastbot."
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
  if [[ "$branch" != "" ]] && [[ "$branch" != "current" ]]; then
     CURRENT_BRANCH=`git rev-parse --abbrev-ref HEAD`
     if [ "$CURRENT_BRANCH" != "$branch" ]; then
       echo "***error: was expecting branch $branch in repo $repodir."
       echo "Found branch $CURRENT_BRANCH. Aborting cfastbot."
       return 1
     fi
  fi
  return 0
}

#---------------------------------------------
#                   usage_all
#---------------------------------------------

function usage_all {
echo ""
echo "Miscellaneous:"
echo "-a - run automatically if cfast repo has changed"
echo "-b - use the current branch"
echo "-f - force cfastbot run"
echo "-F config.sh  - clone repos using revision and tags in config.sh"
echo "-i - use installed smokeview"
echo "-I - compiler [ default: $compiler]"
echo "-k - kill cfastbot"
echo "-m email -  email_address "
echo "-o - specify GH_OWNER when uploading manuals. [default: $GH_OWNER]"
echo "-r - specify GH_REPO when uploading manuals. [default: $GH_REPO]"
echo "-q queue_name - run cases using the queue queue_name"
echo "     default: $QUEUE"
echo "-R - remove run status file"
echo "-U - upload guide (only by user: cfastbot)"
}

#---------------------------------------------
#                   usage
#---------------------------------------------

function usage {
option=$1
echo "Verification and validation testing script for cfast"
echo ""
echo "Options:"
echo "-c - clean repos"
echo "-h - display most commonly used options"
echo "-H - display all options"
echo "-u - update repos"
echo "-v - show options used to run cfastbot"
if [ "$option" == "-H" ]; then
usage_all
fi
exit
}

#---------------------------------------------
#                   is_file_installed
#---------------------------------------------

is_file_installed()
{
  local program=$1
  
  prognotfound=`$program -help | tail -1 | grep "not found" | wc -l`
  if [ "$prognotfound" == "1" ]; then
    echo "***error: the program $program is not installed" 
    return 1
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

#VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
#                             Primary script execution =
#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

if [ ! -d ~/.cfastgit ]; then
  mkdir ~/.cfastgit
fi
cfastbot_pid=~/.cfastgit/cfastbot_pid

CURDIR=`pwd`
QUEUE=$(sinfo -h -o "%P" | grep '\*' | sed 's/\*//')

if [ -e .cfast_git ]; then
  cd ../..
  reponame=`pwd`
  cd $CURDIR
else
  echo "***error: cfastbot not running in the Firemodels repo"
  exit
fi

botrepo=$reponame/bot
botbranch=master

RUNAUTO=
EMAIL=
FORCE=
compiler=intel
size=
REMOVE_PID=

UPLOAD=
KILL_CFASTBOT=
ECHO=
CONFIG=
CLONEREPOS=

while getopts 'aCfF:hHiI:km:o:q:r:RU' OPTION
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
   ;;
  h)
   usage;
   ;;
  H)
   usage -H;
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
   REMOVE_PID=1
   ;;
  U)
   UPLOAD=-U
   ;;
esac
done
shift $(($OPTIND-1))

#*** kill cfastbot

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

#***remove the pid file from cfastbogt's last run

if [ "$REMOVE_PID" == "1" ]; then
  rm -f $cfastbot_pid
  echo "$cfastbot_pid status file removed"
  exit
fi

#*** building a bundle so update all repos using repo info in config.sh

if [ "$CONFIG" != "" ]; then
  if [ -e $CONFIG ]; then
    CONFIG="-F $CONFIG"
  else
    echo ***error: configuration file $CONFIG does not exist
    exit
  fi
  ./update_repos -m
fi

#*** cloning repos so only update bot repo

if [ "$CLONEREPOS" != "" ]; then
  cd $botrepo/scripts
  ./update_repos -b
fi

#*** if both of above 2 if statements are not active use current repos - do not update repos



if [ -e $cfastbot_pid ]; then
  if [ "$FORCE" == "" ]; then
    echo cfastbot is already running. If this is
    echo not the case rerun using the -f option.
    if [ "$RUNAUTO" == "" ]; then
      if [ -e $EMAIL_LIST ]; then
        source $EMAIL_LIST
        echo "Cfastbot was unable to start.  Another instance was already running or it did not complete successfully"  | mail -s "error: cfastbot failed to start" $mailTo > /dev/null
      fi
    fi
    exit
  fi
fi

touch $cfastbot_pid
if [[ "$EMAIL" != "" ]]; then
  EMAIL="-m $EMAIL"
fi

REPO="-r $reponame"
QUEUE="-q $QUEUE"
compiler="-I $compiler"
PID="-p $cfastbot_pid"
cd $CURDIR
echo   ./cfastbot.sh $PID $REPO $CLONEREPOS $RUNAUTO $CONFIG $size $compiler $CLEAN $QUEUE $UPLOAD $EMAIL "$@"
$ECHO  ./cfastbot.sh $PID $REPO $CLONEREPOS $RUNAUTO $CONFIG $size $compiler $CLEAN $QUEUE $UPLOAD $EMAIL "$@"
if [ -e $cfastbot_pid ]; then
  rm $cfastbot_pid
fi

