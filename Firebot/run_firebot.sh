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
echo "-q queue - specify queue [default: $QUEUE]"
echo "-f - force firebot run"
echo "-i - use installed version of smokeview"
if [ "$INTEL" != "" ]; then
  echo "-J - use Intel MPI version fds [default]"
else
  echo "-J - use Intel MPI version fds"
fi
echo "-O - use OpenMPI version fds"
if [ "$EMAIL" != "" ]; then
  echo "-m email_address [default: $EMAIL]"
else
  echo "-m email_address "
fi
echo "-P - remove run status (PID) file"
echo "-S - use startup files to set the environment, not modules"
echo "-U - upload guides (only by user firebot)"
echo ""
echo "Build apps, set repo revisions"
echo "-B - only build apps"
echo "-C - when cloning repos proceed without giving a warning"
echo "-g firebot_host - host where firebot was run"
echo "-G firebot_home - home directory where firebot was run"
echo "   The -g and -G options are used when clonging repos (-R option)"
echo "   to build apps using the same repo revisions as used with the last"
echo "   successful firebot run"
echo "-R branch_name - clone fds, exp, fig, out and smv repos. fds and smv repos"
echo "     will be checked out with a branch named 'branch_name'"
echo "-T - only clone the fds and smv repos (this option is set by default when"
echo "     only building apps (-B) and cloning repos (-R)"
echo "-x fds_rev - run firebot using the fds revision named fds_rev [default: origin/master]"
echo "-y smv_rev - run firebot using the smv revision named smv_rev [default: origin/master]"
echo "   The -x and -y options are only used with the -R cloning option"
}

#---------------------------------------------
#                   usage
#---------------------------------------------

function usage {
option=$1
echo "Verification and validation testing script for FDS"
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

echo $0 $* > command.firebot

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

USEINSTALL=
BRANCH=master
botscript=firebot.sh
UPDATEREPO=
CLEANREPO=
RUNFIREBOT=1
UPLOADGUIDES=
FORCE=
SKIPMATLAB=
KILL_FIREBOT=
export PREFIX=FB_
ECHO=
REMOVE_PID=
CLONE_REPOS=
CLONE_REPOS_ARG=
CLONE_FDSSMV=
BUILD_ONLY=
export QFDS_STARTUP=
FDS_REV=
SMV_REV=
FDS_REV_ARG=
SMV_REV_ARG=
FIREBOT_HOST=
FIREBOT_HOME=
WEB_DIR=
FORCECLONE=

#*** parse command line options

while getopts 'bBcCfg:G:HhiJkm:nOPq:R:STuUvx:y:w:' OPTION
do
case $OPTION  in
  b)
   BRANCH=current
   ;;
  B)
   BUILD_ONLY="-B"
   ;;
  c)
   CLEANREPO="-c"
   ;;
  C)
   FORCECLONE="-C"
   ;;
  f)
   FORCE=1
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
  J)
   INTEL="-J"
   ;;
  k)
   KILL_FIREBOT="1"
   ;;
  m)
   EMAIL="$OPTARG"
   ;;
  n)
   UPDATEREPO=
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
  S)
    export QFDS_STARTUP=1
   ;;
  T)
    CLONE_FDSSMV="-T"
   ;;
  u)
   UPDATEREPO="-u"
   ;;
  U)
   UPLOADGUIDES=-U
   ;;
  v)
   RUNFIREBOT=
   ECHO="echo"
   ;;
  x)
   FDS_REV_ARG="$OPTARG"
   FDS_REV="-x $FDS_REV_ARG"
   ;;
  y)
   SMV_REV_ARG="$OPTARG"
   SMV_REV="-y $SMV_REV_ARG"
   ;;
  w)
   WEB_DIR="$OPTARG"
   ;;
  \?)
  echo "***error: unknown option entered. aborting firebot"
  exit 1
  ;;
esac
done
shift $(($OPTIND-1))

CLONE_REPOS_ARG=$CLONE_REPOS

if [ "$BUILD_ONLY" != "" ]; then
  if [ "$CLONE_REPOS" != "" ]; then
    CLONE_FDSSMV="-T"
  fi
fi

if [ "$WEB_DIR" != "" ]; then
  WEB_DIR="-w $WEB_DIR"
fi

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
  if [ "$RUNFIREBOT" == "" ]; then
    FDS_REVISION=`../Bundle/fds/scripts/get_rev.sh -r fds -g $FIREBOT_HOST -G $FIREBOT_HOME`
    SMV_REVISION=`../Bundle/fds/scripts/get_rev.sh -r smv -g $FIREBOT_HOST -G $FIREBOT_HOME`
  fi
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
      if [ "$FORCECLONE" == "" ]; then
        YOUARE="You are about to erase and clone "
      else
        YOUARE="You are erasing and cloning "
      fi
      if [ "$CLONE_FDSSMV" == "" ]; then
        echo "$YOUARE the fds, exp, fig, out and smv repos."
      else
        echo "$YOUARE the fds and smv repos"
      fi
      if [ "$FORCECLONE" == "" ]; then
        echo "Press any key to continue or <CTRL> c to abort."
        echo "Type $0 -h for other options"
        read val
      fi
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
#     and that the -b branch option only applies to the fds and smv repos

if [[ "$UPDATEREPO" != "" ]]; then
  if [[ "$RUNFIREBOT" == "1" ]]; then
    CD_REPO $repo/bot/Firebot master  || exit 1

    git fetch origin &> /dev/null
    git merge origin/master &> /dev/null
    cd $CURDIR
  fi
fi

if [ "$RUNFIREBOT" == "" ]; then
    echo ""
    echo "Firebot Properties"
    echo "------------------"
  if [ "$CLEANREPO" == "" ]; then
    echo " clean repos: no"
  else
    echo " clean repos: yes"
  fi
  if [ "$UPDATEREPO" == "" ]; then
    echo "update repos: no"
  else
    echo "update repos: yes"
  fi
  if [ "$BUILD_ONLY" == "" ]; then
    echo "  Build only: no"
    echo "       Queue: $QUEUE"
  else
    echo "  Build only: yes"
  fi
  if [ "$INTEL" == "" ]; then
    echo "   INTEL mpi: no"
  else
    echo "   INTEL mpi: yes"
  fi
  echo "      Branch: $BRANCH"
  if [ "$FDS_HASH" != "" ]; then
    echo "    fds hash: $FDS_HASH"
  fi
  if [ "$FDS_REVISION" != "" ]; then
    echo "fds revision: $FDS_REVISION"
  fi
  if [ "$CLONE_REPOS_ARG" != "" ]; then
      echo "  fds branch: $CLONE_REPOS_ARG"
  fi
  if [ "$SMV_HASH" != "" ]; then
    echo "    smv hash: $SMV_HASH"
  fi
  if [ "$SMV_REVISION" != "" ]; then
    echo "smv revision: $SMV_REVISION"
  fi
  if [ "$CLONE_REPOS_ARG" != "" ]; then
      echo "  smv branch: $CLONE_REPOS_ARG"
  fi
  if [ "$CLONE_REPOS" != "" ]; then
    if [ "$CLONE_FDSSMV" == "" ]; then
      echo "       Clone: fds, exp, fig, out and smv repos."
    else
      echo "       Clone: fds and smv repos"
    fi
  fi
fi

# if cloning repos, only update and clean bot repo (which has already been done)

BRANCH="-b $BRANCH"
QUEUE="-q $QUEUE"
touch $firebot_pid
firebot_status=0
$ECHO  ./$botscript -p $firebot_pid $UPDATEREPO $INTEL $BUILD_ONLY $FORCECLONE $BRANCH $FDS_REV $SMV_REV $USEINSTALL $UPLOADGUIDES $CLEANREPO $QUEUE $SKIPMATLAB $CLONE_REPOS $CLONE_FDSSMV  $EMAIL $WEB_DIR "$@"
firebot_status=$?
if [ -e $firebot_pid ]; then
  rm -f $firebot_pid
fi
exit $firebot_status
