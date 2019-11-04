#!/bin/bash

# The Webbot script is part of an automated continuous integration system.

#---------------------------------------------
#                   usage
#---------------------------------------------

function usage {
echo option=$option
echo "Check links in all web pages in the webpages repo"
echo ""
echo "Options:"
echo "-a - run only if the repo has changed since the last time" 
echo "     this script was run"
echo "-c - clean the webpages repo"
echo "-f - force check on all web pages"
echo "-h - display this message"
echo "-u - update the webpages repo"
exit
}


#---------------------------------------------
#                   run_auto
#---------------------------------------------

run_auto()
{
  WEB_DIR=$webrepo

  MESSAGE_FILE=$GIT_STATUS_DIR/message

  update_repo web nist-pages || return 1

# get info for smokeview source directory
  cd $WEB_DIR
  if [ ! -e $GIT_WEB_REVISION_FILE ]; then
    touch $GIT_WEB_REVISION_FILE
  fi

  if [[ $THIS_WEB_REVISION == $LAST_WEB_REVISION ]] ; then
    return 1
  fi

  rm -f $MESSAGE_FILE
  echo $THIS_WEB_REVISION > $GIT_WEB_REVISION_FILE
  echo $THIS_WEB_VERSION > $GIT_WEB_VERSION_FILE
  echo -e "one or more web pages have changed. $LAST_WEB_REVISION->$THIS_WEB_REVISION($THIS_WEBAUTHOR)" >> $MESSAGE_FILE
  cat $GIT_WEB_LOG_FILE >> $MESSAGE_FILE
  echo -e "Webbot run initiated." >> $MESSAGE_FILE
  cat $MESSAGE_FILE | mail -s "webbot run initiated" $mailTo > /dev/null
  return 0
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
#                   MKDIR
#---------------------------------------------

MKDIR ()
{
  local DIR=$1
  
  if [ ! -d $DIR ]
  then
    echo Creating directory $DIR
    mkdir -p $DIR
  fi
}

#---------------------------------------------
#                   clean_smokebot_history
#---------------------------------------------

clean_webbot_history()
{
   
   # Clean Webbot metafiles
   MKDIR $webbotdir           > /dev/null
   cd $webbotdir
   MKDIR $OUTPUT_DIR          > /dev/null
   rm -rf $OUTPUT_DIR/*       > /dev/null
}

#---------------------------------------------
#                   clean_repo
#---------------------------------------------

clean_repo()
{
   local reponame=$1

   cd $repo/$reponame
   git clean -dxf
   return 0
}


#---------------------------------------------
#                   update_repo
#---------------------------------------------

update_repo()
{
   local reponame=$1
   local branch=$2
   
   CD_REPO $repo/$reponame $branch || return 1

   cd $repo/$reponame
   git update-index --refresh
   IS_DIRTY=`git describe --long --dirty | grep dirty | wc -l`
   if [ "$IS_DIRTY" == "1" ]; then
     echo "The repo $repo/$reponame has uncommitted changes."
     echo "Commit or revert these changes"
     return 1
   fi
   echo "Updating branch $branch."   >> $OUTPUT_DIR/stage0 2>&1
   git remote update                 >> $OUTPUT_DIR/stage0 2>&1
   git merge origin/$branch          >> $OUTPUT_DIR/stage0 2>&1
   return 0
}

#---------------------------------------------
#                   check_update_repo
#---------------------------------------------

check_update_repo()
{
   # Check for GIT errors
   if [ -e $OUTPUT_DIR/stage0 ]; then
     if [[ `grep -i -E 'warning|modified' $OUTPUT_DIR/stage0` == "" ]]
     then
        # Continue along
        :
     else
        echo "warnings from Stage 0 - Update repos"                >> $WARNING_LOG
        echo ""                                                    >> $WARNING_LOG
        grep -A 5 -B 5 -i -E 'warning|modified' $OUTPUT_DIR/stage0 >> $WARNING_LOG
        echo ""                                                    >> $WARNING_LOG
     fi
   fi
}

#---------------------------------------------
#                   check_stage1
#---------------------------------------------

check_stage1()
{
   if [[ `grep -rIi 'error:\*\*\*' $OUTPUT_DIR/stage1` = "" ]]
   then
      stage1_success=true
   else
      cp $OUTPUT_DIR/stage1 $OUTPUT_DIR/stage1_errors

      echo "Broken link errors:"          >> $ERROR_LOG
      cat $OUTPUT_DIR/stage1_errors       >> $ERROR_LOG
      echo ""                             >> $ERROR_LOG
   fi
}

#---------------------------------------------
#                   email_build_status
#---------------------------------------------

email_build_status()
{
  echo "              host: $hostname"         >> $TIME_LOG
  echo "  webpages version: $THIS_WEB_VERSION" >> $TIME_LOG
  echo ""                                      >> $TIME_LOG

  cd $webbotdir

  nsummary=`cat output/stage1 | wc -l`
  if [ $nsummary -gt 0 ]; then
    cd $webbotdir
    cat output/stage1 >> $TIME_LOG
  else
    echo "No web pages have changed"             >> $TIME_LOG
  fi

  if [ -e $ERROR_LOG ]; then
    EMAIL_SUBJECT="webbot failure"
  else
    EMAIL_SUBJECT="webbot success"
  fi

  EMAIL_SUBJECT="$EMAIL_SUBJECT on ${hostname}, ${THIS_WEB_VERSION}"
  cat $TIME_LOG | mail -s "$EMAIL_SUBJECT" $mailTo > /dev/null
}

#VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
#                             beginning of webbot.sh
#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

#*** define initial values

GIT_STATUS_DIR=~/.webbot
SAVED_WEB_PAGES=$GIT_STATUS_DIR/webpages

MKDIR $GIT_STATUS_DIR
MKDIR $SAVED_WEB_PAGES

webbotdir=`pwd`
OUTPUT_DIR="$webbotdir/output"

EMAIL_LIST="$HOME/.webbot/webbot_email_list.sh"
ERROR_LOG=$OUTPUT_DIR/errors
WARNING_LOG=$OUTPUT_DIR/warnings
TIME_LOG=$OUTPUT_DIR/time_log
  
GIT_WEB_VERSION_FILE=$GIT_STATUS_DIR/web_version
GIT_WEB_REVISION_FILE=$GIT_STATUS_DIR/web_revision
GIT_WEB_LOG_FILE=$GIT_STATUS_DIR/web_log

THIS_WEBAUTHOR=`git log . | head -2 | tail -1 | awk '{print $2}'`
THIS_WEB_REVISION=`git log --abbrev-commit . | head -1 | awk '{print $2}'`
THIS_WEB_VERSION=`git describe --dirty`
LAST_WEB_REVISION=`cat $GIT_WEB_REVISION_FILE`
git log . | head -5 | tail -1 > $GIT_WEB_LOG_FILE

CLEAN_REPO=
UPDATE_REPO=
FORCE=

WEBBRANCH=nist-pages
RUNAUTO=
mailTo=

#*** parse command line options

while getopts 'acfhu' OPTION
do
case $OPTION in
  a)
   RUNAUTO="y"
   ;;
  c)
   CLEAN_REPO=1
   ;;
  f)
   FORCE=1
   ;;
  h)
   usage
   ;;
  u)
   UPDATE_REPO=1
   ;;
esac
done
shift $(($OPTIND-1))

#*** make sure webbot is running in the right directory

if [ -e .web_git ]; then
  cd ../..
  repo=`pwd`
  cd $webbotdir
else
  echo "***error: webbot not running in the bot/Webbot directory"
  echo "          Aborting Webbot"
  exit 1
fi

#*** create pub directory

MKDIR $HOME/.webbot

botrepo=$repo/bot
webrepo=$repo/webpages

#*** make sure repos needed by smokebot exist

CD_REPO $botrepo $BOTBRANCH || exit 1
if [ "$BOTBRANCH" == "current" ]; then
  cd $botrepo
  BOTBRANCH=`git rev-parse --abbrev-ref HEAD`
fi

CD_REPO $webrepo $WEBBRANCH || exit 1

# if -a option is invoked, only proceed running webbot if
# a page in the web repo has changed

if [[ $RUNAUTO == "y" ]] ; then
  run_auto || exit 1
fi

echo ""
echo "Webbot Settings"
echo "-----------------"
echo "    Web repo: $webrepo"
echo "  Web branch: $WEBBRANCH"
echo "    bot repo: $botrepo"
echo "  bot branch: $BOTBRANCH"
echo "     Run dir: $webbotdir"
echo ""

cd

# Load mailing list for status report
if [ "$mailTo" == "" ]; then
  if [ -e $EMAIL_LIST ]; then
    source $EMAIL_LIST
    mailTo=$mailToWEB
  fi
fi
if [ "$mailTo" == "" ]; then
  mailTo=`git config user.email`
fi
if [ "$mailTo" == "" ]; then
  mailTo=`whoami`@`hostname`
fi
if [ "$mailToWEB" == "" ]; then
  mailToWEB=$mailTo
fi

hostname=`hostname`
clean_webbot_history

if [ "$CLEAN_REPO" == "1" ]; then
  echo "Clean webpages repo"
  clean_repo webpages
fi

if [ "$UPDATE_REPO" == "1" ]; then
  echo "Updating web repo"
  update_repo webpages $WEBBRANCH || exit 1
  check_update_repo
fi

touch $OUTPUT_DIR/stage1
cd $webrepo
for webpage in *.html; do
  webpage_old=$SAVED_WEB_PAGES/$webpage
  CHECK=
  if [ -e $webpage_old ]; then
    ndiffs=`diff $webpage_old $webpage | wc -l`
    if [ $ndiffs -gt 0 ]; then
      CHECK=1
    fi
  else
    CHECK=1
  fi
  if [ "$FORCE" == "1" ]; then
    CHECK=1
  fi
  if [ "$CHECK" == "1" ]; then
    echo "Checking $webpage"
    $webbotdir/check_webpage.sh $webrepo $webpage >> $OUTPUT_DIR/stage1
    cp $webpage $webpage_old
  fi
done

check_stage1

echo "   emailing results"
email_build_status
