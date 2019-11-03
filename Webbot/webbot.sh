#!/bin/bash

# The Webbot script is part of an automated continuous integration system.

#---------------------------------------------
#                   run_auto
#---------------------------------------------

run_auto()
{
  GIT_STATUS_DIR=~/.webbot

  WEB_DIR=$webrepo
  GIT_WEB_REVISION_FILE=$GIT_STATUS_DIR/web_revision
  GIT_WEB_LOG_FILE=$GIT_STATUS_DIR/web_log

  MESSAGE_FILE=$GIT_STATUS_DIR/message

  MKDIR $GIT_STATUS_DIR

  update_repo web nist-pages || return 1

# get info for smokeview source directory
  cd $WEB_DIR
  if [ ! -e $GIT_WEB_REVISION_FILE ]; then
    touch $GIT_WEB_REVISION_FILE
  fi
  THIS_WEBAUTHOR=`git log . | head -2 | tail -1 | awk '{print $2}'`
  THIS_WEB_REVISION=`git log --abbrev-commit . | head -1 | awk '{print $2}'`
  LAST_WEB_REVISION=`cat $GIT_WEB_REVISION_FILE`
  git log . | head -5 | tail -1 > $GIT_WEB_LOG_FILE

  if [[ $THIS_WEB_REVISION == $LAST_WEB_REVISION ]] ; then
    return 1
  fi

  rm -f $MESSAGE_FILE
  SOURCE_CHANGED=1
  echo $THIS_WEB_REVISION>$GIT_WEB_REVISION_FILE
  echo -e "one or more web pages have changed. $LAST_WEB_REVISION->$THIS_WEB_REVISION($THIS_WEBAUTHOR)" >> $MESSAGE_FILE
  cat $GIT_WEB_LOG_FILE >> $MESSAGE_FILE
  echo -e "Webbot run initiated." >> $MESSAGE_FILE
  cat $MESSAGE_FILE | mail -s "webbot run initiated" $mailTo > /dev/null
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
   if [[ `grep -rIi 'error:***` == "" ]]
   then
      stage1_success=true
   else
      grep -rIi 'error:***' > $OUTPUT_DIR/stage1_errors

      echo "Broken link web link errors:" >> $ERROR_LOG
      cat $OUTPUT_DIR/stage1_errors       >> $ERROR_LOG
      echo ""                             >> $ERROR_LOG
   fi
}

#---------------------------------------------
#                   email_build_status
#---------------------------------------------

email_build_status()
{
  echo "----------------------------------------------" > $TIME_LOG
  echo "                host: $hostname " >> $TIME_LOG
  echo "  web version/branch: $WEB_REVISION/$WEBBRANCH" >> $TIME_LOG
  echo "  WEB revisions: old: $LAST_WEB_REVISION new: $THIS_WEB_REVISION" >> $TIME_LOG
  SOURCE_CHANGED=

  if [[ $THIS_WEB_REVISION != $LAST_WEB_REVISION ]] ; then
    SOURCE_CHANGED=1
    cat $GIT_WEB_LOG_FILE >> $TIME_LOG
  fi
  cd $webbotdir

  EMAIL_SUBJECT="web success"
  if [ -e $WARNING_LOG ]; then
    cat $WARNING_LOG >> $TIME_LOG
    echo ""        >> $TIME_LOG
    EMAIL_SUBJECT="webbot failure"
  fi
  if [ -e $ERROR_LOG ]; then
    cat $ERROR_LOG >> $TIME_LOG
    echo ""        >> $TIME_LOG
    EMAIL_SUBJECT="webbot failure"
  fi

  EMAIL_SUBJECT="$EMAIL_SUBJECT on ${hostname}. ${GIT_REVISION}, $WEBBRANCH"
  cat $TIME_LOG | mail -s $EMAIL_SUBJECT $mailTo > /dev/null
}

#VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
#                             beginning of webbot.sh
#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

#*** define initial values

webbotdir=`pwd`
OUTPUT_DIR="$webbotdir/output"

EMAIL_LIST="$HOME/.webbot/webbot_email_list.sh"
ERROR_LOG=$OUTPUT_DIR/errors
WARNING_LOG=$OUTPUT_DIR/warnings
TIME_LOG=$OUTPUT_DIR/time_log

WEBBRANCH=nist-pages
RUNAUTO=
mailTo=

#*** parse command line options

while getopts 'a' OPTION
do
case $OPTION in
  a)
   RUNAUTO="y"
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
webrepo=$repo/web

#*** make sure repos needed by smokebot exist

CD_REPO $botrepo $BOTBRANCH || exit 1
if [ "$BOTBRANCH" == "current" ]; then
  cd $botrepo
  BOTBRANCH=`git rev-parse --abbrev-ref HEAD`
fi

CD_REPO $webrepo $WEBBRANCH || exit 1

# if -a option is invoked, only proceed running webbot if the
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

THIS_WEB_AUTHOR=
THIS_WEB_FAILED=0
WEB_STATUS_FILE=$webrepo/WEB_status
LAST_WEB_FAILED=0
if [ -e $WEB_STATUS_FILE ] ; then
  LAST_WEB_FAILED=`cat $WEB_STATUS_FILE`
fi

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

echo "Updating web repo"
update_repo web $WEBBRANCH || exit 1

check_update_repo

echo "" > $OUTPUT_DIR>stage1
echo "Checking download.html"
$webbotdir/check_webpage.sh $webdir download.html >> $OUTPUT_DIR/stage1

echo "Checking manuals.html"
$webbotdir/check_webpage.sh $webdir manuals.html  >> $OUTPUT_DIR/stage1

check_stage1

echo "   emailing results"
email_build_status
