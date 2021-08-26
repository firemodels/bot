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
echo "-a - only run if the FDS or smokeview source has changed"
echo "-b - use the current branch"
echo "-f - force smokebot to run"
echo "-I compiler - intel or gnu [default: $COMPILER]"
echo "-J use Intel MPI version of fds"
echo "-k - kill smokebot if it is running"
echo "-L - smokebot lite,  build debug apps and run cases using debug fds"
echo "     (no release fds, no release cases, no manuals, etc)"
echo "-q queue [default: $QUEUE]"
if [ "$EMAIL" != "" ]; then
  echo "-m email_address - [default: $EMAIL]"
else
  echo "-m email_address"
fi
echo "-M - make movies"
echo "-P - remove run status (PID) file"
echo "-U - upload guides"
echo "-w directory - web directory containing summary pages"
echo ""
echo "Build apps, set repo revisions:"
echo "-B - only build apps"
echo "-g firebot_host - host where firebot was run"
echo "-G firebot_home - home directory where firebot was run"
echo "   The -g and -G options are used when clonging repos (-R option)"
echo "   to build apps using the same repo revisions as used with the last"
echo "   successful firebot run"
echo "-R release_type (master, release or test) - clone fds, exp, fig, out and smv repos"
echo "   fds and smv repos will be checked out with a branch named"
echo "   master, release or test [default: master]"
echo "-T - only clone the fds and smv repos (this option is set by default when"
echo "     only building apps (-B) and cloning repos (-R) options are used"
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
COMPILER=intel
SMOKEBOT_LITE=
ECHO=
INTEL=
REMOVE_PID=
BUILD_ONLY=
CLONE_REPOS=
FDS_REV=
SMV_REV=
FDS_TAG=
SMV_TAG=
FIREBOT_HOST=
FIREBOT_HOME=
WEB_DIR=
USE_BOT_QFDS=
WEB_ROOT=/var/www/html

#*** check to see if a queing system is available

QUEUE=smokebot
notfound=`qstat -a 2>&1 | tail -1 | grep "not found" | wc -l`
if [ $notfound -eq 1 ] ; then
  QUEUE=none
fi

#*** parse command line options

while getopts 'abBcfg:G:hHI:JkLm:MPq:R:TuUvw:W:x:X:y:Y:' OPTION
do
case $OPTION  in
  a)
   RUNAUTO=-a
   ;;
  b)
   BRANCH="current"
   ;;
  B)
   BUILD_ONLY="-B"
   ;;
  c)
   CLEANREPO=-c
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
   usage
   ;;
  H)
   usage "-H"
   ;;
  I)
   COMPILER="$OPTARG"
   ;;
  J)
   INTEL="-J"
   ;;
  k)
   KILL_SMOKEBOT=1
   ;;
  L)
   SMOKEBOT_LITE="-L"
   ;;
  m)
   EMAIL="$OPTARG"
   ;;
  M)
   MOVIE="-M"
   ;;
  P)
   REMOVE_PID=1
   ;;
  q)
   QUEUE="$OPTARG"
   ;;
  R)
   CLONE_REPOS="$OPTARG"
   ;;
  T)
    CLONE_FDSSMV="-T"
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

if [ "$REMOVE_PID" == "1" ]; then
  rm -f $smokebot_pid
  echo "$smokebot_pid status file removed"
  exit
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
  if [ "$CLONE_REPO" == "" ]; then
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

COMPILER="-I $COMPILER"

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

#*** for now always assume the bot repo is always in the master branch
#    and that the -b branch option only applies to the fds and smv repos

if [[ "$RUNSMOKEBOT" == "1" ]]; then
  if [[ "$UPDATEREPO" == "-u" ]]; then
     CD_REPO $repo/bot/Smokebot $BRANCH || exit 1
     
     git fetch origin &> /dev/null
     git merge origin/master &> /dev/null
  fi
fi

BRANCH="-b $BRANCH"

#*** run smokebot

touch $smokebot_pid
$ECHO ./$botscript $SIZE $BRANCH $FDS_REV $FDS_TAG $SMV_REV $SMV_TAG $CLONE_REPOS $CLONE_FDSSMV $RUNAUTO $INTEL $BUILD_ONLY $COMPILER $SMOKEBOT_LITE $CLEANREPO $WEB_DIR $WEB_ROOT $UPDATEREPO $QUEUE $UPLOAD $EMAIL $MOVIE "$@"
if [ -e $smokebot_pid ]; then
  rm $smokebot_pid
fi

