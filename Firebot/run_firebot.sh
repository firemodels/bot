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
if [ "$QUEUE" != "" ]; then
  echo "-q queue - specify queue [default: $QUEUE]"
else
  echo "-q queue - specify queue"
fi
echo "-f - force firebot run"
if [ "$INTEL" != "" ]; then
  echo "-J - use Intel MPI version fds [default]"
else
  echo "-J - use Intel MPI version fds"
fi
if [ "$EMAIL" != "" ]; then
  echo "-m email_address [default: $EMAIL]"
else
  echo "-m email_address "
fi
echo "-M - only run matlab and build manuals stage"
echo "-O - use OpenMPI version fds"
echo "-P - remove run status (PID) file"
echo "-d - only run cases in debug mode"
echo "-N - skip matlab, pictures and manuals stages"
echo "-U - upload guides (only by user firebot)"
echo "-w webdir - copy firebot web summary to $WEB_ROOT/webdir"
echo "-W webroot - root web directory [default: $WEB_ROOT]"
echo ""
echo "Build apps, set repo revisions"
echo "-B - only build apps"
echo "-C - when cloning repos proceed without giving a warning"
echo "-D firebot is being run using old fds Build directory structure"
echo "-F - clone repos using revisions from latest firebot pass"
echo "-G - upload guides even if not firebot"
echo "-o - specify GH_OWNER when uploading manuals. [default: $GH_OWNER]"
echo "-r - specify GH_REPO when uploading manuals. [default: $GH_REPO]"
echo "-R branch_name - clone fds, exp, fig, out and smv repos. fds and smv repos"
echo "     will be checked out with a branch named 'branch_name'"
echo "-T - only clone the fds and smv repos (this option is set by default when"
echo "     only building apps (-B) and cloning repos (-R)"
echo "-V option - if option is 'all' run all validation cases 1 time step, otherwise"
echo "            run validation cases in fds/Validation/FDS_Val_Cases.sh 1 time step"
echo "-x fds_rev - run firebot using the fds revision named fds_rev [default: origin/master]"
echo "-X fds_tag - when cloning, tag the fds repo using fds_tag"
echo "-y smv_rev - run firebot using the smv revision named smv_rev [default: origin/master]"
echo "-Y smv_tag - when cloning, tag the smv repo using smv_tag"
echo "   The -x and -y options are only used with the -R cloning option"
echo "-z file - use revisions and tags in file to clone repos"
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
  if [ "$branch" != "current" ]; then
  if [ "$branch" != "" ]; then
     CURRENT_BRANCH=`git rev-parse --abbrev-ref HEAD`
     if [ "$CURRENT_BRANCH" != "$branch" ]; then
       echo "***error: was expecting branch $branch in repo $repodir."
       echo "Found branch $CURRENT_BRANCH. Aborting firebot."
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
if [ "$FIREMODELS" != "" ]; then
  export FIREMODELS=$repo
fi

echo $0 $* > command.firebot

#*** checking to see if a queing system is available

notfound=`sinfo 2>&1 | tail -1 | grep "not found" | wc -l`
if [ $notfound -eq 1 ] ; then
  QUEUE=none
fi
if [ "$QUEUE" != "none" ]; then
  QUEUE=`sinfo -ho "%P" | grep *$ | sed -e 's/[*]$//'`
fi

INTEL=
platform="linux"
if [ "`uname`" == "Darwin" ] ; then
  platform="osx"
else
  INTEL="-J"
fi

#*** define initial values

BRANCH=master
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
FDS_REV=
SMV_REV=
FIREBOT_LATEST_PASS=
WEB_DIR=
WEB_ROOT=/var/www/html
FORCECLONE=
DEBUG_MODE=
LOCAL=
MANUALS_MATLAB_ONLY=
FDS_TAG=
SMV_TAG=
VALIDATION=
OPENMPTEST=
CLONEFILE=
BUILD_3RD_PARTY=
FORCE_UPLOAD=

#*** parse command line options

while getopts '3bBcCdDfFhGHJkm:MnNo:OPq:r:R:TuUvV:w:W:x:X:y:Y:z' OPTION
do
case $OPTION  in
  3)
   BUILD_3RD_PARTY=-3
   ;;
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
  d)
   DEBUG_MODE="-d"
   ;;
  D)
   OPENMPTEST=-D
   ;;
  f)
   FORCE=1
   ;;
  F)
   FIREBOT_LATEST_PASS=1
   ;;
  G)
   FORCE_UPLOAD=-G
   ;;
  h)
   usage;
   ;;
  H)
   usage -H;
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
  M)
   MANUALS_MATLAB_ONLY=-M
   ;;
  n)
   UPDATEREPO=
   ;;
  N)
   SKIPMATLAB=-s
   ;;
  o)
   export GH_OWNER="$OPTARG"
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
  r)
   export GH_REPO="$OPTARG"
   ;;
  R)
   CLONE_REPOS="$OPTARG"
   BRANCH=current
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
  V)
   VALIDATION="$OPTARG"
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
  z)
   CLONEFILE="-z"
   ;;
  \?)
  echo "***error: unknown option entered. aborting firebot"
  exit 1
  ;;
esac
done
shift $(($OPTIND-1))

if [ "$VALIDATION" != "" ]; then
  VALIDATION="-V $VALIDATION"
fi

CLONE_REPOS_ARG=$CLONE_REPOS
if [ "$FDS_REV" == "" ]; then
  SMV_REV=
fi
if [ "$SMV_REV" == "" ]; then
  FDS_REV=
fi

if [ "$BUILD_ONLY" != "" ]; then
  if [ "$CLONE_REPOS" != "" ]; then
    CLONE_FDSSMV="-T"
  fi
fi

if [ "$WEB_DIR" != "" ]; then
  WEB_DIR="-w $WEB_DIR"
fi
if [ "$WEB_ROOT" != "" ]; then
  if [ "$WEB_DIR" == "" ]; then
    WEB_ROOT=
  else
    WEB_ROOT="-W $WEB_ROOT"
  fi
fi

# sync fds and smv repos with the the repos used in the last successful firebot run

GET_HASH=
if [ "$FIREBOT_LATEST_PASS" != "" ]; then
  GET_HASH=1
fi

if [ "$FDS_REV" != "" ]; then
  GET_HASH=
fi
if [ "$GET_HASH" != "" ]; then
  if [ "$CLONE_REPOS" == "" ]; then
    echo "***error: The -g and -G options for specifying firebot host/home directory can only be used"
    echo "          when cloning the repos, when the -R option is used"
    exit 1
  fi
  ./getGHfile.sh     FDS_INFO.txt
  FDS_HASH=`grep FDS_HASH  FDS_INFO.txt | awk '{print $2}'`
  SMV_HASH=`grep SMV_HASH  FDS_INFO.txt | awk '{print $2}'`
  FDS_REVISION=`grep FDS_REVISION  FDS_INFO.txt | awk '{print $2}'`
  SMV_REVISION=`grep SMV_REVISION  FDS_INFO.txt | awk '{print $2}'`
  ABORT=
  if [ "$FDS_HASH" == "" ]; then
    ABORT=1
  fi
  if [ "$SMV_HASH" == "" ]; then
    ABORT=1
  fi
  if [ "$ABORT" != "" ]; then
    echo "***error: the fds and/or smv repo hash could not be found at"
    echo "          github.com/$GH_OWNER/$GH_REPO tag: $GH_FDS_TAG"
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
      JOBIDS=`squeue | grep $PREFIX | awk -v user="$USER" '{if($4==user){print $1}}' | awk -F'.' '{print $1}'`
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

if [[ "$RUNFIREBOT" == "1" ]]; then
  if [ -d $repo/bot/Firebot ]; then
    cd $repo/bot/Firebot
    BOT_BRANCH=`git rev-parse --abbrev-ref HEAD`
  else
    echo "***error: directory $repo/bot/Firebot does not exist"
    exit
  fi

  if [ "$BOT_BRANCH" == "master" ]; then
    CD_REPO $repo/bot/Firebot master  || exit 1

    git fetch origin &> /dev/null
    git merge origin/master &> /dev/null
  else
    echo "***warning: bot repo is in $BOT_BRANCH branch not master, will not be updated"
  fi
  cd $CURDIR
fi

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

# if cloning repos, only update and clean bot repo (which has already been done)

BRANCH="-b $BRANCH"
if [ "$QUEUE" == "" ]; then
  echo "***error: a queue is not defined. Use the -q option to define a queue to run cases."
  exit
else
  QUEUE="-q $QUEUE"
fi
touch $firebot_pid
firebot_status=0
$ECHO  ./firebot.sh -p $firebot_pid $BUILD_3RD_PARTY $UPDATEREPO $INTEL $OPENMPTEST $BUILD_ONLY $FORCE_UPLOAD $FORCECLONE $BRANCH $DEBUG_MODE $MANUALS_MATLAB_ONLY $FDS_REV $FDS_TAG $SMV_REV $SMV_TAG $UPLOADGUIDES $CLEANREPO $QUEUE $SKIPMATLAB $CLONE_REPOS $CLONE_FDSSMV $VALIDATION $CLONEFILE $EMAIL $WEB_ROOT $WEB_DIR "$@"
firebot_status=$?
if [ -e $firebot_pid ]; then
  rm -f $firebot_pid
fi
exit $firebot_status
