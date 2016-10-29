#!/bin/bash
CUR=`pwd`
allrepos="bot cfast cor exp fds out radcal smv"
otherrepos="webpages wikis"
BRANCH=master
PUSH=

function usage {
echo "Show git status for fds repos"
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
   echo "***error: the update_repos.sh script must be run from"
   echo "          the bot/Scripts directory"
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

SHOW_STATUS ()
{
  local repo=$1
  repodir=$FMROOT/$repo

  echo "------------- $repo -------------------------------------------"
  if [ ! -e $repodir ]; then
     echo "Skipping, $repo does not exist"
     return
  fi
  cd $repodir
  git update-index --refresh
  git status -uno
  git describe --dirty
}

SHOW_STATUS2 ()
{
  local repo=$1
  repodir=$FMROOT/$repo

  if [ ! -e $repodir ]; then
     return
  fi
  echo "------------- $repo -------------------------------------------"
  cd $repodir
  git update-index --refresh
  git status -uno
  git describe --dirty
}

for repo in $allrepos
do 
  echo
  SHOW_STATUS $repo
done

for repo in $otherrepos
do 
  echo
  SHOW_STATUS2 $repo
done

cd $CURDIR
