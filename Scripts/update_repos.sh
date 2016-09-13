#!/bin/bash
CUR=`pwd`
allrepos="bot cfast cor exp fds out radcal smv"
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

for repo in $allrepos
do 
  echo
  repodir=$FMROOT/$repo
  echo "---------------------------------------------------------------"
  if [ ! -e $repodir ]; then
     echo "$repo does not exist, not updating"
     continue;
  fi
  cd $repodir
  CURRENT_BRANCH=`git rev-parse --abbrev-ref HEAD`
  if [ "$BRANCH" != "$CURRENT_BRANCH" ]; then
    echo $BRANCH branch not checked out in $repo
    echo update skipped
    continue;
  fi
  echo "updating $repo from origin"
  git fetch origin
  git merge origin/$BRANCH
  have_central=`git remote -v | awk '{print $1}' | grep firemodels | wc  -l`
  if [ "$have_central" -gt "0" ]; then
     echo "updating $repo from firemodels"
     git fetch firemodels
     git merge firemodels/$BRANCH
     if [ "$PUSH" == "1" ]; then
         echo "pushing changes in $repo to origin"
         git push origin $BRANCH
     fi
   fi
done
echo
echo repo updating complete
cd $CURDIR
