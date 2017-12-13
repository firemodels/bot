#!/bin/bash
CUR=`pwd`
allrepos="bot cfast cor exp fds out radcal smv fds.wiki fds-smv"
BRANCH=master

function usage {
echo "Show remotes for repos $allrepos if they exist"
echo ""
echo "Options:"
echo "-h - display this message"
exit
}

FMROOT=
if [ -e ../.gitbot ]; then
   cd ../..
   FMROOT=`pwd`
else
   echo "***error: this script must be run from the bot/Scripts directory"
   exit
fi

while getopts 'h' OPTION
do
case $OPTION  in
  h)
   usage;
   ;;
esac
done
shift $(($OPTIND-1))

for repo in $allrepos
do 
  repodir=$FMROOT/$repo

  if [ "$repo" == "fds.wiki" ]; then
     repo=wikis
     repodir=$FMROOT/wikis
  fi
  if [ "$repo" == "fds-smv" ]; then
     repo=webpages
     repodir=$FMROOT/webpages
  fi
  if [ ! -e $repodir ]; then
     continue;
  fi
  echo
  echo "---------------------------------------------------------------"
  cd $repodir
  GITHEADER=`git remote -v | grep origin | head -1 | awk  '{print $2}' | awk -F ':' '{print $1}'`
  if [ "$GITHEADER" == "git@github.com" ]; then
     GITHEADER="git@github.com:"
     GITUSER=`git remote -v | grep origin | head -1 | awk -F ':' '{print $2}' | awk -F\/ '{print $1}'`
  else
     GITHEADER="https://github.com/"
     GITUSER=`git remote -v | grep origin | head -1 | awk -F '.' '{print $2}' | awk -F\/ '{print $2}'`
  fi
  echo "$repo remotes:"
  git remote -v
done
cd $CURDIR
