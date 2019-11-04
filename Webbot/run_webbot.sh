#!/bin/bash
EMAIL_LIST="$HOME/.webbot/webbot_email_list.sh"

# The Webbot script is part of an automated continuous integration system.

#---------------------------------------------
#                   usage
#---------------------------------------------

function usage {
echo option=$option
echo "Check links in all web pages in the webpages repo"
echo ""
echo "Options:"
echo "-a - run webbot only if the webpages repo has changed"
echo "     since the last time webbot was run"
echo "-A - check all web pages in the webpages repo"
echo "-c - clean the webpages repo"
echo "-f - force webbot to run"
echo "-h - display this message"
echo "-k - kill webbot if it is running"
echo "-u - update the webpages repo"
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

#VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
#                             beginning of run_smokebot.sh
#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

#*** make sure webbot is started in the right location

CURDIR=`pwd`
if [ -e .web_git ]; then
  cd ../..
  repo=`pwd`
  cd $CURDIR
else
  echo "***error: webbot not running in the bot/Webbot  directory"
  exit
fi

#*** define initial values

CLEAN_REPO=
UPDATE_REPO=
FORCE=
RUNAUTO=
KILL_WEBBOT=
WEBBOT_PID=~/.webbot/PID
FORCE_WEBBOT=

#*** parse command line options

while getopts 'aAcfkhu' OPTION
do
case $OPTION in
  a)
   RUNAUTO="-a"
   ;;
  A)
   CHECK_ALL="-A"
   ;;
  c)
   CLEAN_REPO="-c"
   ;;
  f)
   FORCE_WEBBOT=1
   ;;
  k)
   KILL_WEBBOT=1
   ;;
  h)
   usage
   ;;
  u)
   UPDATE_REPO="-u"
   ;;
esac
done
shift $(($OPTIND-1))

#*** kill webbot
if [ "$KILL_WEBBOT" == "1" ]; then
  if [ -e $WEBBOT_PID ]; then
    PID=`head -1 $WEBBOT_PID`

    echo "killing webbot (PID=$PID)"
    kill -9 $PID

    echo webbot process $PID killed
    rm -f $WEBBOT_PID
  else
    echo webbot not running
  fi
  exit
fi

#*** abort if webbot is already running
if [ "$FORCE_WEBBOT" == "" ]; then
  if [ -e $WEBBOT_PID ] ; then
    echo Webbot is running.
    echo "If this is not the case, re-run with the -f option."
    if [ "$RUNAUTO" == "" ]; then
      if [ -e $EMAIL_LIST ]; then
        source $EMAIL_LIST
        echo "Webbot was unable to start.  Another instance was already running or it did not complete successfully"  | mail -s "error: webbot failed to start" $mailToWEB > /dev/null
      fi
    fi
    exit 1
  fi
fi

#*** for now always assume the bot repo is always in the master branch
#    and that the -b branch option only apples to the fds and smv repos

if [[ "$UPDATEREPO" == "-u" ]]; then
   CD_REPO $repo/bot/Webbot $BRANCH || exit 1
     
   git fetch origin &> /dev/null
   git merge origin/master &> /dev/null
fi

#*** run webbot

./webbot.sh $RUNAUTO $CLEAN_REPO $CHECK_ALL $UPDATE_REPO
rm -f $WEBBOT_PID


