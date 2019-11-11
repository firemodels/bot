#!/bin/bash

# The Firebot script is part of an automated continuous integration system.
# Consult the FDS Config Management Plan for more information.

#---------------------------------------------
#                   usage_all
#---------------------------------------------

function usage_all {
echo ""
echo "Miscellaneous:"
echo "-b - use the current branch"
echo "-B - only build apps"
echo "-D - run only debug stages "
echo "-q queue - specify queue [default: $QUEUE]"
echo "-f - force firebot run"
echo "-F - skip figure generation and build document stages"
echo "-g firebot_host - host where firebot was run"
echo "-G firebot_home - home directory where firebot was run"
echo "   the -g and -G options are only used with the -R option and"
echo "   are used to build apps using  the same repo revisions as last"
echo "    successful firebot run "
echo "-i - use installed version of smokeview"
echo "-I - use development version of fds"
echo "-J - use Intel MPI version fds"
echo "-L - firebot lite,  run only stages that build a debug fds and run cases with it"
echo "                    (no release fds, no release cases, no matlab, etc)"
echo "-M   clone fds, exp, fig, out and smv repos. fds and smv repos will be checked out"
echo "     with a branch named master"
echo "-N - don't copy Manuals directory to .firebot/Manuals"
echo "-O - use OpenMPI version fds"
if [ "$EMAIL" != "" ]; then
  echo "-m email_address [default: $EMAIL]"
else
  echo "-m email_address "
fi
echo "-P - remove run status (PID) file"
echo "-R branch_name - clone fds, exp, fig, out and smv repos. fds and smv repos"
echo "     will be checked out with a branch named 'branch_name'"
echo "-s - skip matlab and build document stages"
echo "-S - use startup files to set the environment, not modules"
echo "-T - only clone the fds and smv repos"
echo "-U - upload guides (only by user firebot)"
echo "-x fds_rev - run firebot using the fds revision named fds_rev [default: origin/master]"
echo "-y smv_rev - run firebot using the smv revision named smv_rev [default: origin/master]"
echo "   The -x and -y options are only used with the -R cloning option"
}

#---------------------------------------------
#                   usage
#---------------------------------------------

function usage {
option=$1
echo "Verification testing script for FDS"
echo ""
echo "Options:"
echo "-c - clean repos"
echo "-h - display most commonly used options"
echo "-H - display all options"
echo "-k - kill firebot if it is running"
echo "-u - update repos"
echo "-v - show options used to run firebot"
if [ "$option" == "-H" ]; then
usage_all
fi
exit 0
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

if [ ! -d ~/.fdssmvgit ] ; then
  mkdir ~/.fdssmvgit
fi
firebot_pid=~/.fdssmvgit/firesmokebot_pid

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

echo $0 $* > output/command.firebot

#*** checking to see if a queing system is available

QUEUE=firebot
notfound=`qstat -a 2>&1 | tail -1 | grep "not found" | wc -l`
if [ $notfound -eq 1 ] ; then
  QUEUE=none
fi

INTEL=
platform="linux"
if [ "`uname`" == "Darwin" ] ; then
  platform="osx"
else
  INTEL="-J"
fi

#*** define initial values

COPY_MANUAL_DIR=
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
export PREFIX=FB_
ECHO=
debug_mode=
DV=
REMOVE_PID=
CLONE_REPOS=
CLONE_FDSSMV=
BUILD_ONLY=
DEBUG_ONLY=
export QFDS_STARTUP=
FDS_REV=
SMV_REV=
FIREBOT_HOST=
FIREBOT_HOME=

#*** parse command line options

while getopts 'bBcdDFfg:G:HhIiJkLm:MNnOPq:R:SsTuUvx:y:' OPTION
do
case $OPTION  in
  b)
   BRANCH=current
   ;;
  B)
   BUILD_ONLY="-B"
   ;;
  c)
   CLEANREPO=1
   ;;
  d)
    debug_mode="-d "
   ;;
  D)
    DEBUG_ONLY="-D"
   ;;
  f)
   FORCE=1
   ;;
  F)
   SKIPFIGURES=-F
   ;;
  g)
   FIREBOT_HOST="$OPTARG"
   ;;
  G)
   FIREBOT_HOME="$OPTARG"
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
   DV="-I"
   ;;
  J)
   INTEL="-J"
   ;;
  k)
   KILL_FIREBOT="1"
   ;;
  L)
   FIREBOT_LITE=-L
   ;;
  m)
   EMAIL="$OPTARG"
   ;;
  M)
   CLONE_REPOS="master"
   ;;
  N)
   COPY_MANUAL_DIR=-N
   ;;
  n)
   UPDATEREPO=0
   ;;
  O)
   INTEL=
   ;;
  P)
   REMOVE_PID=1
   ;;
  q)
   QUEUE="$OPTARG"
   ;;
  R)
   CLONE_REPOS="$OPTARG"
   BRANCH=current
   ;;
  s)
   SKIPMATLAB=-s
   ;;
  S)
    export QFDS_STARTUP=1
   ;;
  T)
    CLONE_FDSSMV="-T"
   ;;
  u)
   UPDATEREPO=1
   ;;
  U)
   UPLOADGUIDES=-U
   ;;
  v)
   RUNFIREBOT=
   ECHO="echo"
   ;;
  x)
   FDS_REV="-x $OPTARG"
   ;;
  y)
   SMV_REV="-y $OPTARG"
   ;;
  \?)
  echo "***error: unknown option entered. aborting firebot"
  exit 1
  ;;
esac
done
shift $(($OPTIND-1))

# sync fds and smv repos with the the repos used in the last successful firebot run

GET_HASH=
if [ "$FIREBOT_HOST" != "" ]; then
  GET_HASH=1
else
  FIREBOT_HOST=`hostname`
fi
if [ "$FIREBOT_HOME" != "" ]; then
  GET_HASH=1
else
  FIREBOT_HOME=\~firebot
fi
if [ "$GET_HASH" != "" ]; then
  if [ "$CLONE_REPOS" == "" ]; then
    echo "***error: The -g and -G options for specifying firebot host/home directory can only be used"
    echo "          when cloning the repos, when the -R option is used"
    exit 1
  fi
  FDS_HASH=`../Bundle/fds/scripts/get_hash.sh -r fds -g $FIREBOT_HOST -G $FIREBOT_HOME`
  SMV_HASH=`../Bundle/fds/scripts/get_hash.sh -r smv -g $FIREBOT_HOST -G $FIREBOT_HOME`
  ABORT=
  if [ "$FDS_HASH" == "" ]; then
    ABORT=1
  fi
  if [ "$SMV_HASH" == "" ]; then
    ABORT=1
  fi
  if [ "$ABORT" != "" ]; then
    echo "***error: the fds and/or smv repo hash could not be found in the directory"
    echo "          $FIREBOT_HOME/.firebot/apps at the host $FIREBOT_HOST"
    exit 1
  fi
  FDS_REV="-x $FDS_HASH"
  SMV_REV="-y $SMV_HASH"
fi

# warn user (if not the firebot user) if using the clone option

if [ "$RUNFIREBOT" != "" ]; then
  if [ "`whoami`" != "firebot" ]; then
    if [ "$CLONE_REPOS" != "" ]; then
      if [ "$CLONE_FDSSMV" == "" ]; then
        echo "You are about to erase and clone the fds, exp, fig"
        echo "out and smv repos."
      else
        echo "You are about to erase and clone the fds and smv repos"
      fi
      echo "Press any key to continue or <CTRL> c to abort."
      echo "Type $0 -h for other options"
      read val
    fi
  fi
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

    if [ "$QUEUE" == "none" ]; then
      cd $CURDIR/../Scripts
      ./killppids.sh ../Firebot/scriptfiles
      cd $CURDIR
    else
      JOBIDS=`qstat -a | grep $PREFIX | awk -v user="$USER" '{if($2==user){print $1}}' | awk -F'.' '{print $1}'`
      if [ "$JOBIDS" != "" ]; then
        echo killing firebot jobs with Id:$JOBIDS
        qdel $JOBIDS
      fi
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

if [ "$REMOVE_PID" == "1" ]; then
  rm -f $firebot_pid
  echo "$firebot_pid status file removed"
  exit 0
fi

#*** abort if firebot is already running

if [ -e $firebot_pid ] ; then
  if [ "$FORCE" == "" ] ; then
    echo Firebot or smokebot are already running. If this
    echo "is not the case re-run using the -f option."
    exit 1
  fi
fi

if [[ "$EMAIL" != "" ]]; then
  EMAIL="-m $EMAIL"
fi

#***  for now always assume the bot repo is always in the master branch
#     and that the -b branch option only apples to the fds and smv repos

if [[ "$UPDATEREPO" == "1" ]]; then
  UPDATE=-u
  if [[ "$RUNFIREBOT" == "1" ]]; then
    CD_REPO $repo/bot/Firebot master  || exit 1

    git fetch origin &> /dev/null
    git merge origin/master &> /dev/null
    cd $CURDIR
  fi
fi
if [[ "$CLEANREPO" == "1" ]]; then
  CLEAN=-c
fi

# if cloning repos, only update and clean bot repo (which has already been done)

BRANCH="-b $BRANCH"
QUEUE="-q $QUEUE"
touch $firebot_pid
firebot_status=0
$ECHO  ./$botscript -p $firebot_pid $UPDATE $DV $INTEL $debug_mode $BUILD_ONLY $BRANCH $FDS_REV $SMV_REV $FIREBOT_LITE $USEINSTALL $UPLOADGUIDES $CLEAN $QUEUE $SKIPMATLAB $SKIPFIGURES $CLONE_REPOS $CLONE_FDSSMV  $EMAIL $COPY_MANUAL_DIR $DEBUG_ONLY "$@"
firebot_status=$?
if [ -e $firebot_pid ]; then
  rm -f $firebot_pid
fi
exit $firebot_status
