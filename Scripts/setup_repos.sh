#!/bin/bash

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
echo "-w - setup wiki and webpage repos cloned from firemodels"
echo "-h - display this message"
exit
}

CURDIR=`pwd`

fdsrepos="exp fds out smv"
smvrepos="cfast fds smv"
cfastrepos="cfast exp smv"
allrepos="cfast cor exp fds out radcal smv"
wikiwebrepos="fds.wiki fds-smv"
repos=$fdsrepos

FMROOT=
WIKIWEB=
if [ -e ../.gitbot ]; then
   cd ../..
   FMROOT=`pwd`
else
   echo "***Error: setup_repos.sh must be run from the bot/Scripts directory"
   exit
fi

while getopts 'acfshw' OPTION
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
  w)
   WIKIWEB=1;
   repos=$wikiwebrepos;
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
if [ "$WIKIWEB" == "1" ]; then
   echo "from git@github.com:firemodels into the directory: $FMROOT"
else
   echo "from $GITHEADER$GITUSER into the directory: $FMROOT"
fi
echo ""
echo "Press any key to continue or <CTRL> c to abort."
echo "Type $0 -h for other options"
read val

for repo in $repos bot
do 
  echo
  repodir=$FMROOT/$repo
  cd $FMROOT
  echo "----------------------------------------------"
  if [ "$repo" == "fds.wiki" ]; then
     echo repo: wikis
     repodir=$FMROOT/wikis
     if [ -e $repodir ]; then
        echo "   repo already exists"
     else
        git clone ${GITHEADER}firemodels/$repo.git wikis
     fi
     continue
  fi   
  if [ "$repo" == "fds-smv" ]; then
     echo repo: webpages
     repodir=$FMROOT/webpages
     if [ -e $repodir ]; then
        echo "   repo already exists"
     else
        git clone ${GITHEADER}firemodels/$repo.git webpages
     fi
     continue
  fi
  echo repo: $repo
  AT_GITHUB=`git ls-remote $GITHEADER$GITUSER/$repo.git 2>&1 > /dev/null | grep ERROR | wc -l`
  if [ $AT_GITHUB -gt 0 ]; then
     echo "***Error: The repo $GITHEADER$GITUSER/$repo.git was not found."
     continue;
  fi 
  RECURSIVE=
  if [ "$repo" == "exp" ]; then
     RECURSIVE=--recursive
  fi
  if [ -e $repodir ]; then
     echo "   repo already exists"
  else
     git clone $RECURSIVE $GITHEADER$GITUSER/$repo.git
  fi
  cd $repodir
  if [ "$GITUSER" == "firemodels" ]; then
     ndisable=`git remote -v | grep DISABLE | wc -l`
     if [ $ndisable -eq 0 ]; then
        echo disabling push access to firemodels
        git remote set-url --push origin DISABLE
     fi
  else
     have_central=`git remote -v | awk '{print $1}' | grep firemodels | wc -l`
     if [ $have_central -eq 0 ]; then
        echo setting up remote tracking with firemodels
        git remote add firemodels ${GITHEADER}firemodels/$repo.git
        git remote update
     fi
     ndisable=`git remote -v | grep DISABLE | wc -l`
     if [ $ndisable -eq 0 ]; then
        echo "   disabling push access to firemodels"
        git remote set-url --push firemodels DISABLE
     else
        echo "   push access to firemodels already disabled"
     fi
  fi
done
cd $CURDIR
