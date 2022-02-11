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
  if [ "$branch" != "" ]; then
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
echo "-3 - run in 32 bit mode (only for gnu compilers)"
echo "-a - run automatically if cfast repo has changed"
echo "-f - force cfastbot run"
echo "-i - use installed smokeview and background (if using the 'none' queue)"
echo "-I - compiler [ default: $compiler]"
echo "-k - kill cfastbot"
echo "-m email -  email_address "
echo "-q queue_name - run cases using the queue queue_name"
echo "     default: $QUEUE"
echo "-R - remove run status file"
echo "-s - skip matlab and guide generating stages"
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

# checking to see if a queing system is available
QUEUE=smokebot
notfound=`qstat -a 2>&1 | tail -1 | grep "not found" | wc -l`
if [ $notfound -eq 1 ]; then
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

botrepo=$reponame/bot
botbranch=master

RUNAUTO=
UPDATEREPO=
CLEANREPO=0
RUNCFASTBOT=1
EMAIL=
FORCE=
compiler=intel
size=
REMOVE_PID=

MATLABEXE=
SKIP=
havematlab=`which matlab 2> /dev/null | wc -l`

UPLOAD=
USEINSTALL=
KILL_CFASTBOT=
ECHO=

while getopts 'acfhHiI:km:Mq:RsuUv' OPTION
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
  H)
   usage -H;
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
  R)
   REMOVE_PID=1
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
   ECHO=echo
   ;;
esac
done
shift $(($OPTIND-1))

if [ "$REMOVE_PID" == "1" ]; then
  rm -f $cfastbot_pid
  echo "$cfastbot_pid status file removed"
  exit
fi

if [ "$KILL_CFASTBOT" == "1" ]; then
  if [ -e $cfastbot_pid ] ; then
    PID=`head -1 $cfastbot_pid`
    echo killing process invoked by cfastbot
    kill -9 $(LIST_DESCENDANTS $PID)
    echo "killing cfastbot (PID=$PID)"
    kill -9 $PID
    if [ "$QUEUE" != "none" ]; then
      JOBIDS=`qstat -a | grep CB_ | awk -v user="$USER" '{if($2==user){print $1}}'`
      if [ "$JOBIDS" != "" ]; then
        echo killing cfastbot jobs with Id:$JOBIDS
        qdel $JOBIDS
      fi
    fi
    echo cfastbot process $PID killed
  else
    echo cfastbot is not running, cannot be killed.
  fi
  exit
fi

if [ "$USEINSTALL" != "" ]; then
  echo
  echo looking for installed software
  is_file_installed smokeview || exit 1
  is_file_installed background || exit 1
  echo "   found smokeview"
  echo "   found background"
fi

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
if [[ "$UPDATEREPO" == "1" ]]; then
   UPDATEREPO=-u
   if [ "$RUNCFASTBOT" == "1" ]; then
     CD_REPO $botrepo $botbranch || exit 1
     git fetch origin
     git merge origin/$botbranch

     have_remote=`git remote -v | awk '{print $1}' | grep firemodels | wc  -l`
     if [ "$have_remote" != "0" ]; then
       git fetch firemodels
       git merge firemodels/$botbranch
     fi
     
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
$ECHO  ./cfastbot.sh $PID $REPO $USEINSTALL $RUNAUTO $size $compiler $UPDATEREPO $CLEAN $QUEUE $SKIP $MATLABEXE $UPLOAD $EMAIL "$@"
if [ -e $cfastbot_pid ]; then
  rm $cfastbot_pid
fi   
