#!/bin/bash
CUR=`pwd`
allrepos="bot cfast cor exp fds out radcal smv"
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
   echo "***error: the update_repos.sh script must be run from the bot/Scripts directory"
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
  echo
  repodir=$FMROOT/$repo
  echo "---------------------------------------------------------------"
  if [ ! -e $repodir ]; then
     echo "$repo does not exist, not skipping"
     continue;
  fi
  cd $repodir
  echo "$repo remotes:"
  git remote -v
done
cd $CURDIR
