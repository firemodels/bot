#!/bin/bash
CUR=`pwd`
allrepos="bot cfast fds fig smv"
otherrepos="webpages wikis"

FMROOT=
if [ -e ../.gitbot ]; then
   cd ../..
   FMROOT=`pwd`
else
   echo "***error: this script must be run from the bot/Scripts directory"
   exit
fi

PRUNE_REPO ()
{
  local repo=$1
  repodir=$FMROOT/$repo

  echo "------------- $repo -------------------------------------------"
  if [ ! -e $repodir ]; then
     echo "Skipping, $repo does not exist"
     return
  fi
  cd $repodir
  git remote prune origin
}

for repo in $allrepos
do 
  echo
  PRUNE_REPO $repo
done

echo prune complete

cd $CURDIR
