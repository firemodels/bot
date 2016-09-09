#!/bin/bash
allrepos="cfast cor exp fds out radcal smv"
BRANCH=master
PUSH=

function usage {
echo "Update the repos $allrepos if they exist"
echo ""
echo "Options:"
echo "-h - display this message"
echo "-p - push update to remote origin"
exit
}

while getopts 'hp' OPTION
do
case $OPTION  in
  h)
   usage;
   ;;
  p)
   PUSH=1
   ;;
esac
done
shift $(($OPTIND-1))

CURDIR=`pwd`
cd ../..
FIREMODELS=`pwd`
for repo in $
do 
  echo
  repodir=$FIREMODELS/$repo
  echo "-------------------------------"
  if [ -e $repodir ]; then
     cd $repodir
     CURRENT_BRANCH=`git rev-parse --abbrev-ref HEAD`
     if [ "$BRANCH" == "$CURRENT_BRANCH" ]; then
       echo "updating $repo from origin"
       git fetch origin
       git merge origin/$BRANCH
       have_remote=`git remote -v | grep firemodels | wc  -l`
       if [ "$have_remote" -gt "0" ]; then
          echo "updating $repo from firemodels"
          git fetch firemodels
          git merge firemodels/$BRANCH
       else
          if [ "$PUSH" == "1" ]; then
             echo "pushing $repo updates to origin"
             git push origin $BRANCH
          fi
       fi
     else
       echo repo not in branch $BRANCH
       echo update skipped
     fi
  else
     echo "$repo does not exist, not updating"
  fi
done
echo repo creation complated
cd $CURDIR
