#!/bin/bash
CUR=`pwd`
allrepos="bot cad cfast cor exp fds fig out radcal smv test_bundles"
otherrepos="webpages wikis"
BRANCH=master
CHECKOUT_MASTER=

function usage {
echo "Update the repos $allrepos if they exist"
echo ""
echo "Options:"
echo "-h - display this message"
echo "-m - checkout master branch before updating"
echo "-w - update only webpages and wikis repos"
exit
}

FMROOT=
WEBWIKI_ONLY=
if [ -e ../.gitbot ]; then
   cd ../..
   FMROOT=`pwd`
else
   echo "***error: this script must be run from the bot/Scripts directory"
   exit
fi

while getopts 'hmw' OPTION
do
case $OPTION  in
  h)
   usage;
   ;;
  m)
   CHECKOUT_MASTER=1
   ;;
  w)
   WEBWIKI_ONLY=1
   ;;
esac
done
shift $(($OPTIND-1))

UPDATE_REPO ()
{
  local repo=$1
  repodir=$FMROOT/$repo

  echo "------------- $repo -------------------------------------------"
  if [ ! -e $repodir ]; then
     echo "Skipping, $repo does not exist"
     return
  fi
  cd $repodir
  if [ "$CHECKOUT_MASTER" != "" ]; then
    git checkout master
  fi 
  CURRENT_BRANCH=`git rev-parse --abbrev-ref HEAD`
  if [ "$BRANCH" != "$CURRENT_BRANCH" ]; then
    echo "Skipping, found branch $CURRENT_BRANCH, expecting branch $BRANCH"
    return
  fi
  echo ""
  echo "***  updating from origin"
  echo "     branch: $BRANCH"
  echo "     dir: $repodir"

  git remote update
  git merge origin/$BRANCH
  have_central=`git remote -v | awk '{print $1}' | grep firemodels | wc  -l`
  if [ "$have_central" -gt "0" ]; then
     echo ""
     echo "*** updating from firemodels"
     echo "    branch: $BRANCH"
     echo "    dir: $repodir"
     git merge firemodels/$BRANCH
     ahead=`git status -uno | grep ahead | wc -l`
     if [ "$ahead" -gt "0" ]; then
        git push origin $BRANCH
     fi
  fi
  if [[ "$repo" == "exp" ]]; then
     git submodule foreach git remote update
     git submodule foreach git merge origin/master
  fi
}

UPDATE_REPO2 ()
{
  local repo=$1
  repodir=$FMROOT/$repo

  if [ ! -e $repodir ]; then
     return
  fi
  echo "------------- $repo -------------------------------------------"
  cd $repodir
  if [ "$CHECKOUT_MASTER" != "" ]; then
    git checkout master
  fi 
  BRANCH=`git rev-parse --abbrev-ref HEAD`
  echo ""
  echo "***  updating from firemodels"
  echo "     branch: $BRANCH"
  echo "     dir: $repodir"
  echo ""
  git fetch origin
  git merge origin/$BRANCH
  git status -uno
}

if [ "$WEBWIKI_ONLY" == "" ]; then
  for repo in $allrepos
  do 
    echo
    UPDATE_REPO $repo
  done
fi

for repo in $otherrepos
do 
  echo
  UPDATE_REPO2 $repo
done
echo update complete

cd $CURDIR
