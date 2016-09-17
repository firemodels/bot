#!/bin/bash
if [ ! -d ~/.fdssmvgit ] ; then
  mkdir ~/.fdssmvgit
fi
smokebot_pid=~/.fdssmvgit/smokebot_pid

CURDIR=`pwd`
if [ -e .smv_git ]; then
  cd ../..
  repo=`pwd`
  cd $CURDIR
else
  echo "***error: smokebot not running in the bot/Smokebot  directory"
  exit
fi

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

WEB_URL=
web_DIR=/var/www/html/`whoami`
if [ -d $web_DIR ]; then
  IP=`wget http://ipinfo.io/ip -qO -`
  HOST=`host $IP | awk '{printf("%s\n",$5);}'`
  WEB_URL=http://$HOST/`whoami`
else
  web_DIR=
fi

# checking to see if a queing system is available
QUEUE=smokebot
notfound=`qstat -a 2>&1 | tail -1 | grep "not found" | wc -l`
if [ $notfound -eq 1 ] ; then
  QUEUE=none
fi

function usage {
echo "Verification and validation testing script for smokeview"
echo ""
echo "Options:"
echo "-a - run automatically if FDS or smokeview source has changed"
#echo "-b - branch_name - run smokebot using the branch branch_name [default: $BRANCH]"
echo "-c - clean repo"
echo "-f - force smokebot run"
echo "-h - display this message"
echo "-I compiler - intel or gnu [default: $COMPILER]"
if [ "$EMAIL" != "" ]; then
echo "-k - kill smokebot if it is running"
echo "-m email_address - [default: $EMAIL]"
else
echo "-m email_address"
fi
echo "-q queue [default: $QUEUE]"
echo "-L - smokebot lite,  run only stages that build a debug fds and run cases with it"
echo "                    (no release fds, no release cases, no manuals, etc)"
echo "-M  - make movies"
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

CHK_REPO ()
{
  repodir=$1
  if [ ! -e $repodir ]; then
     echo "***error: the repo directory $repodir does not exist."
     echo "          Aborting smokebot."
     exit
  fi
}

CD_REPO ()
{
  repodir=$1
  branch=$2
  CHK_REPO $repodir

  cd $repodir
  if [ "$branch" != "" ]; then
     CURRENT_BRANCH=`git rev-parse --abbrev-ref HEAD`
     if [ "$CURRENT_BRANCH" != "$branch" ]; then
       echo "***error: was expecting branch $branch in repo $repodir."
       echo "Found branch $CURRENT_BRANCH. Aborting smokebot."
       exit
     fi
  fi
}

LIST_DESCENDANTS ()
{
  local children=$(ps -o pid= --ppid "$1")

  for pid in $children
  do
    LIST_DESCENDANTS "$pid"
  done

  echo "$children"
}


while getopts 'aAb:cd:fhI:kLm:Mq:r:tuUvw:W:' OPTION
do
case $OPTION  in
  a)
   RUNAUTO=-a
   ;;
  A)
   RUNAUTO=-A
   ;;
  b)
#   BRANCH="$OPTARG"
    echo "***Warning: -b option for specifying a branch is not supported at this time"
   ;;
  c)
   CLEANREPO=-c
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
  q)
   QUEUE="$OPTARG"
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

if [ "$KILL_SMOKEBOT" == "1" ]; then
  if [ -e $smokebot_pid ]; then
    PID=`head -1 $smokebot_pid`
    echo killing processes invoked by smokebot
    kill -9 $(LIST_DESCENDANTS $PID)
    echo "killing smokebot (PID=$PID)"
    kill -9 $PID
    JOBIDS=`qstat -a | grep SB_ | awk -v user="$USER" '{if($2==user){print $1}}'`
    if [ "$JOBIDS" != "" ]; then
      echo killing smokebot jobs with Id: $JOBIDS
      qdel $JOBIDS
    fi
    echo smokebot process $PID killed
    if [ -e $smokebot_pid ]; then
      rm $smokebot_pid
    fi
  else
    echo smokebotbot is not running, cannot be killed.
  fi
  exit
fi
if [[ "$RUNSMOKEBOT" == "1" ]]; then
  if [ "$FORCE" == "" ]; then
    if [ -e $smokebot_pid ] ; then
      echo Smokebot or firebot are already running.
      echo "Re-run using the -f option if this is not the case."
      exit
    fi
  fi
fi

QUEUE="-q $QUEUE"

if [ "$EMAIL" != "" ]; then
  EMAIL="-m $EMAIL"
fi

# for now always assume the bot repo is always in the master branch
# and that the -b branch option only apples to the fds and smv repos

if [[ "$RUNSMOKEBOT" == "1" ]]; then
  if [[ "$UPDATEREPO" == "-u" ]]; then
     CD_REPO $repo/bot/Smokebot master
     
     git fetch origin &> /dev/null
     git merge origin/master &> /dev/null
  fi
fi

BRANCH="-b $BRANCH"

if [[ "$RUNSMOKEBOT" == "1" ]]; then
  touch $smokebot_pid
  ./$botscript $TESTFLAG $RUNAUTO $COMPILER $SMOKEBOT_LITE $CLEANREPO $web_DIR $WEB_URL $UPDATEREPO $QUEUE $UPLOAD $EMAIL $MOVIE "$@"
  rm $smokebot_pid
else
  echo ./$botscript $TESTFLAG $RUNAUTO $COMPILER $SMOKEBOT_LITE $CLEANREPO $web_DIR $WEB_URL $UPDATEREPO $QUEUE $UPLOAD $EMAIL $MOVIE "$@"
fi
