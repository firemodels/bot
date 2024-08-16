#!/bin/bash
EMAIL_LIST="$HOME/.smokebot/smokebot_email_list.sh"

# The Smokebot script is part of an automated continuous integration system.
# Consult the FDS Config Management Plan for more information.

#---------------------------------------------
#                   usage_all
#---------------------------------------------

function usage_all {
echo ""
echo "Miscellaneous:"
echo "-a - only run if the smokeview source has changed"
echo "-A - only run if smokebot_trigger.txt has changed"
echo "-b - use the current branch"
echo "-f - force smokebot to run"
echo "-k - kill smokebot if it is running"
echo "-q queue [default: $QUEUE]"
echo "-Q - generate images on node running this script"
if [ "$EMAIL" != "" ]; then
  echo "-m email_address - [default: $EMAIL]"
else
  echo "-m email_address"
fi
echo "-M - make movies"
echo "-t - don't run benchmark cases"
echo "-U - upload guides"
echo "-w directory - web directory containing summary pages"
echo ""
echo "Build apps, set repo revisions:"
echo "-C - force clone"
echo "-D use gnu compilers"
echo "-o - specify GH_OWNER when uploading manuals. [default: $GH_OWNER]"
echo "-r - specify GH_REPO when uploading manuals. [default: $GH_REPO]"
echo "-R release_type (master, release or test) - clone fds, exp, fig, out and smv repos"
echo "-s dir - use cached fds, Verification and Verification_dbg directories"
echo "         located under the directory dir"
echo "   fds and smv repos will be checked out with a branch named"
echo "   master, release or test [default: master]"
echo "-S - build smokeview using the Intel sanitize option"
echo "     (only if the 2024 or later compiler is installed)"
echo "-x fds_rev - checkout fds repo using fds_rev revision [default: origin/master]"
echo "-X fds_tag - when cloning, tag the fds repo with fds_tag"
echo "-y smv_rev - checkout smv repo using smv_rev revision [default: origin/master]"
echo "-Y smv_tag - when cloning, tag the smv repo with smv_tag"
echo "   the -x and -y options are only used with the -R option i.e. when"
echo "   the repos are being cloned"
}

#---------------------------------------------
#                   usage
#---------------------------------------------

function usage {
option=$1
echo "Verification testing script for smokeview"
echo ""
echo "Options:"
echo "-c - clean repo"
echo "-h - display most commonly used options"
echo "-H - display all options"
echo "-u - update repo"
echo "-v - show options used to run smokebot"
if [ "$option" == "-H" ]; then
usage_all
fi
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
     echo "          Aborting smokebot."
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
  if [ "$branch" != "current" ]; then
    if [ "$branch" != "" ]; then
      CURRENT_BRANCH=`git rev-parse --abbrev-ref HEAD`
      if [ "$CURRENT_BRANCH" != "$branch" ]; then
        echo "***error: was expecting branch $branch in repo $repodir."
        echo "Found branch $CURRENT_BRANCH. Aborting smokebot."
        return 1
      fi
    fi
  fi
  return 0
}

#---------------------------------------------
#                   LIST_DESCENDANTS
#---------------------------------------------

LIST_DESCENDANTS ()
{
  if [ "$1" != "" ]; then
    local children=$(pgrep -P $1)

    for pid in $children
    do
      LIST_DESCENDANTS $pid
    done
    echo "$children"
  fi
}

#VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
#                             beginning of run_smokebot.sh
#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

#*** location of smokebot processor id

if [ ! -d ~/.fdssmvgit ] ; then
  mkdir ~/.fdssmvgit
fi
smokebot_pid=~/.fdssmvgit/firesmokebot_pid

#*** make sure smokebot is started in the right location

CURDIR=`pwd`
if [ -e .smv_git ]; then
  cd ../..
  repo=`pwd`
  cd $CURDIR
else
  echo "***error: smokebot not running in the bot/Smokebot  directory"
  exit
fi

#*** define initial values

SIZE=
KILL_SMOKEBOT=
BRANCH=master
botscript=smokebot.sh
RUNAUTO=
CLEANREPO=
UPDATEREPO=
RUNSMOKEBOT=1
MOVIE=
UPLOAD=
FORCE=
FORCECLONE=
ECHO=
CLONE_REPOS=
FDS_REV=
SMV_REV=
FDS_TAG=
SMV_TAG=
SANITIZE=
WEB_DIR=
USE_BOT_QFDS=
WEB_ROOT=/var/www/html
GNU=
CACHE_DIR=
DONOT_RUN_BENCHMARK=

#*** check to see if a queing system is available

QUEUE=smokebot
SQUEUE=
notfound=`qstat -a 2>&1 | tail -1 | grep "not found" | wc -l`
if [ $notfound -eq 1 ] ; then
  QUEUE=none
fi

#*** parse command line options

while getopts 'aAB:bcCDfFhHJkm:Mo:q:Qr:R:s:StTuUvw:W:x:X:y:Y:' OPTION
do
case $OPTION  in
  a)
   RUNAUTO=-a
   ;;
  A)
   RUNAUTO=-A
   ;;
  b)
   BRANCH="current"
   ;;
  B)
   BRANCH="$OPTARG"
   ;;
  c)
   CLEANREPO=-c
   ;;
  C)
   FORCECLONE="-C"
   ;;
  D)
   GNU="-D"
   ;;
  f)
   FORCE=1
   ;;
  h)
   usage
   ;;
  H)
   usage "-H"
   ;;
  J)
   DUMMY=
   ;;
  k)
   KILL_SMOKEBOT=1
   ;;
  m)
   EMAIL="$OPTARG"
   ;;
  M)
   MOVIE="-M"
   ;;
  o)
   export GH_OWNER="$OPTARG"
   ;;
  q)
   QUEUE="$OPTARG"
   ;;
  Q)
   SQUEUE=-Q
   ;;
  r)
   export GH_REPO="$OPTARG"
   ;;
  s)
   CACHE_DIR="-s $OPTARG"
   ;;
  S)
   SANITIZE=-S
   ;;
  R)
   CLONE_REPOS="$OPTARG"
   ;;
  t)
   DONOT_RUN_BENCHMARK=-t
   ;;
  u)
   UPDATEREPO=-u
   ;;
  U)
   UPLOAD="-U"
   ;;
  v)
   RUNSMOKEBOT=
   ECHO=echo
   ;;
  w)
   WEB_DIR="$OPTARG"
   ;;
  W)
   WEB_ROOT="$OPTARG"
   ;;
  x)
   FDS_REV="-x $OPTARG"
   ;;
  X)
   FDS_TAG="-X $OPTARG"
   ;;
  y)
   SMV_REV="-y $OPTARG"
   ;;
  Y)
   SMV_TAG="-Y $OPTARG"
   ;;
  \?)
  echo "***error: unknown option entered. aborting smokebot"
  exit 1
esac
done
shift $(($OPTIND-1))

# sync fds and smv repos with the the repos used in the last successful firebot run

# warn user (if not the smokebot user) if using the clone option

if [ `whoami` != smokebot ]; then
  if [ "$CLONE_REPOS" != "" ]; then
    echo "You are about to erase and clone the "
    echo "fds, exp, fig, out and smv repos."
    echo "Press any key to continue or <CTRL> c to abort."
    echo "Type $0 -h for other options"
#    read val
  fi
fi

if [ "$CLONE_REPOS" != "" ]; then
  if [ "$CLONE_REPOS" != "release" ]; then
    if [ "$CLONE_REPOS" != "test" ]; then
      CLONE_REPO="master"
    fi
  fi
  CLONE_REPOS="-R $CLONE_REPOS"
fi

if [ "$WEB_DIR" != "" ]; then
  WEB_DIR="-w $WEB_DIR"
fi
if [ "$WEB_ROOT" != "" ]; then
  WEB_ROOT="-W $WEB_ROOT"
fi

#*** kill smokebot

if [ "$KILL_SMOKEBOT" == "1" ]; then
  if [ -e $smokebot_pid ]; then
    PID=`head -1 $smokebot_pid`

    echo killing smokebot processes descended from: $PID
    JOBS=$(LIST_DESCENDANTS $PID)
    if [ "$JOBS" != "" ]; then
      echo killing processes invoked by smokebot: $JOBS
      kill -9 $JOBS
    fi

    if [ "$QUEUE" == "none" ]; then
      cd $CURDIR/../Scripts
      ./killppids.sh ../Smokebot/scriptfiles
      cd $CURDIR
    else
      JOBIDS=`qstat -a | grep SB_ | awk -v user="$USER" '{if($2==user){print $1}}' | awk -F'.' '{print $1}'`
      if [ "$JOBIDS" != "" ]; then
        echo killing smokebot jobs with Id: $JOBIDS
        qdel $JOBIDS
      fi
    fi
    
    echo "killing smokebot (PID=$PID)"
    kill -9 $PID

    echo smokebot process $PID killed
    rm -f $smokebot_pid
  else
    echo smokebot not running
  fi
  exit
fi

#*** make sure smokebot is not already running

if [[ "$RUNSMOKEBOT" == "1" ]]; then
  if [ "$FORCE" == "" ]; then
    if [ -e $smokebot_pid ] ; then
      echo Smokebot or firebot are running.
      echo "If this is not the case, -f option."
      if [ "$RUNAUTO" == "" ]; then
        if [ -e $EMAIL_LIST ]; then
          source $EMAIL_LIST
          echo "Smokebot was unable to start.  Another instance was already running or it did not complete successfully"  | mail -s "error: smokebot failed to start" $mailToSMV > /dev/null
        fi
      fi
      exit 1
    fi
  fi
fi

QUEUE="-q $QUEUE"

if [ "$EMAIL" != "" ]; then
  EMAIL="-m $EMAIL"
fi

if [[ "$RUNSMOKEBOT" == "1" ]]; then
   CD_REPO $repo/bot/Smokebot $BRANCH || exit 1
    
   if [ "$BRANCH" == "master" ]; then 
     git fetch origin &> /dev/null
     git merge origin/master &> /dev/null
   fi
fi

BRANCH="-b $BRANCH"

#*** run smokebot

touch $smokebot_pid
$ECHO ./$botscript $SIZE $BRANCH $SANITIZE $FDS_REV $FDS_TAG $SMV_REV $SMV_TAG $CLONE_REPOS $CACHE_DIR $FORCECLONE $GNU $RUNAUTO $DONOT_RUN_BENCHMARK $CLEANREPO $WEB_DIR $WEB_ROOT $UPDATEREPO $QUEUE $SQUEUE $UPLOAD $EMAIL $MOVIE "$@"
if [ -e $smokebot_pid ]; then
  rm $smokebot_pid
fi

