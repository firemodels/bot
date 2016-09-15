#!/bin/bash
WEBREPO=$1
WEBBRANCH=$2

oldpage=~/.smokebot/oldpage
newpage=~/.smokebot/newpage
olddata=~/.smokebot/old_data
newdata=~/.smokebot/smv_times.csv
running=~/.fdssmvgit/bot_running
curdir=`pwd`
EXIT="yes"

# don't update status page if smokebot is running
if [ -e $running ] ; then
   exit
fi

# check if status web page has changed

./make_pubpage.sh -s -b  > $newpage
if [ ! -e $oldpage ]; then
  cp $newpage $oldpage
fi
ndiff=`diff $oldpage $newpage|wc -l`
if [ ! "$ndiff" == "0" ] ; then
  cp $newpage $oldpage
  EXIT="no"
fi

# check if FDS benchmark times have changed

./make_timelist.sh -s > $newdata
if [ ! -e $olddata ]; then
  cp $newdata $olddata
fi
ndiff=`diff $olddata $newdata|wc -l`
if [ ! "$ndiff" == "0" ] ; then
   cp $newdata $olddata
   EXIT="no"
fi

# if nothing has changed then exit without committing any files
if [ "$EXIT" == "yes" ]; then
   exit
fi

./make_pubpage.sh -s > $newpage

if [ "$USER" != "smokebot" ]; then
   exit
fi
if [ ! -e $WEBREPO ]; then
   exit
fi
CURRENT_BRANCH=`git rev-parse --abbrev-ref HEAD`
if [ "$CURRENT_BRANCH" != "$WEBBRANCH" ];  then
   exit
fi
cd $WEBREPO

git fetch origin
git merge origin/$WEBBRANCH

cp $newpage smokebot_status.html

#disable pushing until we are sure it  is working

#git add smokebot_status.html
#git commit -m "smokebot: update smokebot status page `date`"
#git push origin $WEBBRANCH
