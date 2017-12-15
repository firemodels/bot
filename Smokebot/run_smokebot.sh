#!/bin/bash

# The Smokebot script is part of an automated continuous integration system.
# Consult the FDS Config Management Plan for more information.
#---------------------------------------------
#                   usage
#---------------------------------------------

function usage {
echo "Verification and validation testing script for smokeview"
echo ""
echo "Options:"
echo "-c - clean repo"
echo "-h - display most commonly used options"
echo "-H - display all options"
echo "-u - update repo"
echo "-v - show options used to run smokebot"
exit
}


#---------------------------------------------
#                   usage_all
#---------------------------------------------

function usage_all {
echo "Verification and validation testing script for smokeview"
echo ""
echo "Options:"
echo "-a - run automatically if FDS or smokeview source has changed"
echo "-b - branch_name - run smokebot using the branch branch_name "
echo "                   [default: $BRANCH]"
echo "-B - use startup files to set the environment not modules"
echo "-c - clean repo"
echo "-C - add --mca plm_rsh_agent /usr/bin/ssh to mpirun command "
echo "           when running cases"
echo "-f - force smokebot run"
echo "-h - display most commonly used options"
echo "-H - display all options"
echo "-I compiler - intel or gnu [default: $COMPILER]"
echo "-J use Intel MPI version of fds"
echo "-k - kill smokebot if it is running"
echo "-q queue [default: $QUEUE]"
echo "-L - smokebot lite,  run only stages that build a debug fds and run"
echo "     cases with it (no release fds, no release cases, no manuals, etc)"
if [ "$EMAIL" != "" ]; then
echo "-m email_address - [default: $EMAIL]"
else
echo "-m email_address"
fi
echo "-M - make movies"
echo "-S - skip picture generating and build manual stages"
echo "-t - use test smokeview"
echo "-u - update repo"
echo "-U - upload guides"
echo "-v - show options used to run smokebot"
if [ "$web_DIR" == "" ]; then
echo "-w directory - web directory containing summary pages"
else
echo "-w directory - web directory containing summary pages [default: $web_DIR]"
fi
if [ "$WEB_URL" == "" ]; then
echo "-W url - web url of summary pages"
else
echo "-W url - web url of summary pages [default: $WEB_URL]"
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
  if [ "$branch" != "" ]; then
     CURRENT_BRANCH=`git rev-parse --abbrev-ref HEAD`
     if [ "$CURRENT_BRANCH" != "$branch" ]; then
       echo "***error: was expecting branch $branch in repo $repodir."
       echo "Found branch $CURRENT_BRANCH. Aborting smokebot."
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

#VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
#                             beginning of run_smokebot.sh
#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

#*** location of smokebot processor id

if [ ! -d ~/.fdssmvgit ] ; then
  mkdir ~/.fdssmvgit
fi
smokebot_pid=~/.fdssmvgit/smokebot_pid

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
NOPT=
INTEL=
export MPIRUN_MCA=
export QFDS_STARTUP=
SKIP=

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

while getopts 'aAb:BcCd:fhHI:JkLm:NMq:r:StuUvw:W:' OPTION
do
case $OPTION  in
  a)
   RUNAUTO=-a
   ;;
  A)
   RUNAUTO=-A
   ;;
  B)
   export QFDS_STARTUP=1
   ;;
  b)
   BRANCH="$OPTARG"
   ;;
  c)
   CLEANREPO=-c
   ;;
  C)
   export MPIRUN_MCA="--mca plm_rsh_agent /usr/bin/ssh "
   ;;
  I)
   COMPILER="$OPTARG"
   ;;
  f)
   FORCE=1
   ;;
  h)
   usage
   exit
   ;;
  H)
   usage_all
   exit
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
  N)
   NOPT="-N"
   ;;
  q)
   QUEUE="$OPTARG"
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
esac
done
shift $(($OPTIND-1))

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
      echo Smokebot or firebot are already running.
      echo "Re-run using the -f option if this is not the case."
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
$ECHO ./$botscript $SKIP $NOPT $SIZE $BRANCH $TESTFLAG $RUNAUTO $INTEL $COMPILER $SMOKEBOT_LITE $CLEANREPO $web_DIR $WEB_URL $UPDATEREPO $QUEUE $UPLOAD $EMAIL $MOVIE "$@"
if [ -e $smokebot_pid ]; then
  rm $smokebot_pid
fi

