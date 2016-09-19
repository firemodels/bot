#!/bin/bash
CUR=`pwd`
allrepos="bot cfast cor exp fds out radcal smv"
otherrepos="webpages wikis"
BRANCH=master
PUSH=

function usage {
echo "Update the repos $allrepos if they exist"
echo ""
echo "Options:"
echo "-h - display this message"
echo "-p - push updates to remote origin"
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

while getopts 'hp' OPTION
do
case $OPTION  in
  h)
   usage;
   ;;
  p)
   PUSH="1";
   ;;
esac
done
shift $(($OPTIND-1))

echo "You are about update repos in the directory $FMROOT."
echo ""
echo "Press any key to continue or <CTRL> c to abort."
read val

UPDATE_REPO3 ()
{
  repodir=$1

  if [ ! -e $repodir ]; then
     exit;
  fi
  echo "---------------------------------------------------------------"
  cd $repodir
  echo "updating $repodir from origin"
  CURRENT_BRANCH=`git rev-parse --abbrev-ref HEAD`
  if [ "$BRANCH" != "$CURRENT_BRANCH" ]; then
    echo "Skipping, found branch $CURRENT_BRANCH, expecting branch $BRANCH"
    exit
  fi
  git fetch origin
  git merge origin/$BRANCH
}

for repo in $otherrepos
do 
  echo
  repodir=$FMROOT/$repo
  UPDATE_REPO3 $repodir
done

cd $CURDIR
