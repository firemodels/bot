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
echo "-a - run script only if the webpages repo has changed"
echo "     since the last time this script was run"
echo "-c - clean the webpages repo"
echo "-f - force check on all web pages"
echo "-h - display this message"
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

#*** parse command line options

#*** parse command line options

while getopts 'acfhu' OPTION
do
case $OPTION in
  a)
   RUNAUTO="-a"
   ;;
  c)
   CLEAN_REPO="-c"
   ;;
  f)
   FORCE="-f"
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

#*** for now always assume the bot repo is always in the master branch
#    and that the -b branch option only apples to the fds and smv repos

if [[ "$UPDATEREPO" == "-u" ]]; then
   CD_REPO $repo/bot/Webbot $BRANCH || exit 1
     
   git fetch origin &> /dev/null
   git merge origin/master &> /dev/null
fi

#*** run webbot

./webbot.sh $RUNAUTO $CLEAN_REPO $FORCE $UPDATE_REPO

