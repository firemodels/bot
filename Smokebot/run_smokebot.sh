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
echo "-a - run automatically if FDS or smokeview source has changed"
echo "-A - run automatically if smokeview source has changed"
echo "-b - use the current branch"
echo "-B - only build apps"
echo "-C - add --mca plm_rsh_agent /usr/bin/ssh to mpirun command "
echo "           when running cases"
echo "-D - use startup files to set the environment not modules"
echo "-f - force smokebot run"
echo "-I compiler - intel or gnu [default: $COMPILER]"
echo "-J use Intel MPI version of fds"
echo "-k - kill smokebot if it is running"
echo "-L - smokebot lite,  run only stages that build a debug fds and run"
echo "     cases with it (no release fds, no release cases, no manuals, etc)"
echo "-q queue [default: $QUEUE]"
if [ "$EMAIL" != "" ]; then
echo "-m email_address - [default: $EMAIL]"
else
echo "-m email_address"
fi
echo "-M - make movies"
echo "-P - remove run status (PID) file"
echo "-R release_type (master, release or test) - clone fds, exp, fig, out and smv repos"
echo "     fds and smv repos will be checked out with a branch named"
echo "     master, release or test [default: master]"
echo "-S - skip picture generating and build manual stages"
echo "-t - use test smokeview"
echo "-U - upload guides"
if [ "$web_DIR" == "" ]; then
echo "-w directory - web directory containing summary pages"
else
echo "-w directory - web directory containing summary pages [default: $web_DIR]"
fi
if [ "$WEB_URL" == "" ]; then
echo "-W url - web url of summary pages"
else
echo "-W url - web url of summary pages [default: $WEB_URL]"
echo "-x fds_rev - run smokebot using the fds revision named fds_rev [default: origin/master]"
echo "-y smv_rev - run smokebot using the smv revision named smv_rev [default: origin/master]"
echo "   the -x and -y options are only used with the -R option i.e. when"
"        the repos are being cloned"
fi
}

#---------------------------------------------
#                   usage
#---------------------------------------------

function usage {
option=$1
echo option=$option
echo "Verification and validation testing script for smokeview"
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
#  local children=$(ps -o pid= --ppid "$1")
  local children=$(pgrep -P $1)

  for pid in $children
  do
    LIST_DESCENDANTS $pid
  done

  echo "$children"
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
TESTFLAG=
ECHO=
INTEL=
export MPIRUN_MCA=
export QFDS_STARTUP=
SKIP=
REMOVE_PID=
BUILD_ONLY=
CLONE_REPOS=
FDS_REV=
SMV_REV=

WEB_URL=
web_DIR=/var/www/html/`whoami`
if [ -d $web_DIR ]; then
  IP=`wget http://ipinfo.io/ip -qO -`
  HOST=`host $IP | awk '{printf("%s\n",$5);}'`
  WEB_URL=http://$HOST/`whoami`
else
  web_DIR=
fi

#*** check to see if a queing system is available

QUEUE=smokebot
notfound=`qstat -a 2>&1 | tail -1 | grep "not found" | wc -l`
if [ $notfound -eq 1 ] ; then
  QUEUE=none
fi

#*** parse command line options

while getopts 'aAbBcCd:DfhHI:JkLm:MPq:r:R:StuUvw:W:x:y:' OPTION
do
case $OPTION  in
  a)
   RUNAUTO=-a
   ;;
  A)
   RUNAUTO=-A
   ;;
  B)
   BUILD_ONLY="-B"
   ;;
  b)
   BRANCH="current"
   ;;
  c)
   CLEANREPO=-c
   ;;
  C)
   export MPIRUN_MCA="--mca plm_rsh_agent /usr/bin/ssh "
   ;;
  D)
   export QFDS_STARTUP=1
   ;;
  I)
   COMPILER="$OPTARG"
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
  S)
   SKIP="-S"
   ;;
  t)
   TESTFLAG="-t"
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
   web_DIR="$OPTARG"
   ;;
  W)
   WEB_URL="$OPTARG"
   ;;
  x)
   FDS_REV="-y $OPTARG"
   ;;
  y)
   SMV_REV="-z $OPTARG"
   ;;
esac
done
shift $(($OPTIND-1))

if [ "$REMOVE_PID" == "1" ]; then
  rm -f $smokebot_pid
  echo "$smokebot_pid status file removed"
  exit
fi

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

if [ ! "$web_DIR" == "" ]; then
  web_DIR="-w $web_DIR"
fi
if [ ! "$WEB_URL" == "" ]; then
  WEB_URL="-W $WEB_URL"
fi

COMPILER="-I $COMPILER"

#*** kill smokebot

if [ "$KILL_SMOKEBOT" == "1" ]; then
  if [ -e $smokebot_pid ]; then
    PID=`head -1 $smokebot_pid`

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
#    and that the -b branch option only apples to the fds and smv repos

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
$ECHO ./$botscript $SKIP $SIZE $BRANCH $FDS_REV $SMV_REV $TESTFLAG $CLONE_REPOS $RUNAUTO $INTEL $BUILD_ONLY $COMPILER $SMOKEBOT_LITE $CLEANREPO $web_DIR $WEB_URL $UPDATEREPO $QUEUE $UPLOAD $EMAIL $MOVIE "$@"
if [ -e $smokebot_pid ]; then
  rm $smokebot_pid
fi

