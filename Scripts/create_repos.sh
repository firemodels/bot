#!/bin/bash
CURDIR=`pwd`

fdsrepos="exp fds out smv"
smvrepos="cfast fds smv"
cfastrepos="cfast exp smv"
allrepos="cfast cor exp fds out radcal smv"
repos=$fdsrepos

function usage {
echo "Create repos used by cfast, fds and/or smokview"
echo ""
echo "Options:"
echo "-a - setup all available repos: "
echo "    $allrepos"
echo "-c - setup repos used by cfastbot: "
echo "    $cfastrepos"
echo "-f - setup repos used by firebot: "
echo "    $fdsrepos"
echo "-s - setup repos used by smokebot: "
echo "    $smvrepos"
echo "-h - display this message"
exit
}

FMROOT=
if [ -e ../.gitbot ]; then
   cd ../..
   FMROOT=`pwd`
else
   echo "***Error: create_repos.sh must be run from the bot/Scripts directory"
   exit
fi

while getopts 'acfsh' OPTION
do
case $OPTION  in
  a)
   repos=$allrepos;
   ;;
  c)
   repos=$cfastrepos;
   ;;
  f)
   repos=$fdsrepos;
   ;;
  h)
   usage;
   ;;
  s)
   repos=$smvrepos;
   ;;
esac
done
shift $(($OPTIND-1))

cd $FMROOT/bot
GITHEADER=`git remote -v | grep origin | head -1 | awk  '{print $2}' | awk -F ':' '{print $1}'`
if [ "$GITHEADER" == "git@github.com" ]; then
   GITHEADER="git@github.com:" 
   GITUSER=`git remote -v | grep origin | head -1 | awk -F ':' '{print $2}' | awk -F\/ '{print $1}'`
else
   GITHEADER="https://github.com/"
   GITUSER=`git remote -v | grep origin | head -1 | awk -F '.' '{print $2}' | awk -F\/ '{print $2}'`
fi

echo "You are about to clone the repos: $repos"
echo "from $GITHEADER$GITUSER into the directory: $FMROOT"
echo ""
echo "Press any key to continue or <CTRL> c to abort."
echo "Type $0 -h for other options"
read val

for repo in $repos
do 
  echo
  repodir=$FMROOT/$repo
  cd $FMROOT
  echo "----------------------------------------------"
  if [ -e $repodir ]; then
     echo Skipping $repo, the directory $repodir already exists.
     continue;
  fi
  AT_GITHUB=`git ls-remote $GITHEADER$GITUSER/$repo.git 2>&1 > /dev/null | grep ERROR | wc -l`
  if [ $AT_GITHUB -gt 0 ]; then
     echo "***Error: The repo $GITHEADER$GITUSER/$repo.git was not found."
     continue;
  fi 
  RECURSIVE=
  if [ "$repo" == "exp" ]; then
     RECURSIVE=--recursive
  fi
  git clone $RECURSIVE $GITHEADER$GITUSER/$repo.git
  if [ "$GITUSER" != "firemodels" ]; then
     echo setting up remote tracking with firemodels
     cd $repodir
     git remote add firemodels ${GITHEADER}firemodels/$repo.git
     git remote update
  fi
done
cd $CURDIR
