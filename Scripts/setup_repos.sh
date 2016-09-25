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
echo "-t - setup fds, smv and webpages repos that can be tagged"
echo "     (have push access to firemodels)"
echo "-w - setup wiki and webpage repos cloned from firemodels"
echo "-h - display this message"
exit
}

CURDIR=`pwd`

tagrepos="fds smv fds-smv"
fdsrepos="exp fds out smv"
smvrepos="cfast fds smv"
cfastrepos="cfast exp smv"
allrepos="cfast cor exp fds out radcal smv"
wikiwebrepos="fds.wiki fds-smv"
repos=$fdsrepos
tagrepo=0

FMROOT=
WIKIWEB=
if [ -e ../.gitbot ]; then
   cd ../..
   FMROOT=`pwd`
else
   echo "***Error: setup_repos.sh must be run from the bot/Scripts directory"
   exit
fi

while getopts 'acfhstw' OPTION
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
  t)
   tagrepo=1
   repos=$tagrepos;
   ;;
  w)
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

for repo in $repos
do 
  echo
  repo_out=$repo

  cd $FMROOT

  echo "----------------------------------------------"
  if [ "$repo" == "fds.wiki" ]; then
     repo_out=wikis
     WIKIWEB=1
  fi
  if [ "$repo" == "fds-smv" ]; then
     repo_out=webpages
     WIKIWEB=1
  fi
  if [ "$tagrepo" == "1" ]; then
     repo_out=${repo_out}_tag
  fi
  repo_dir=$FMROOT/$repo_out
  if [ -e $repo_dir ]; then
     echo "   For repo $repo, the directory $repo_dir already exists"
     continue;
  fi

  echo repo: $repo
  if [ "$WIKIWEB" == "1" ]; then
     cd $FMROOT
     git clone ${GITHEADER}firemodels/$repo.git $repo_out
     continue
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
  git clone $RECURSIVE $GITHEADER$GITUSER/$repo.git $repo_out

  cd $repo_dir
  if [ "$GITUSER" == "firemodels" ]; then
     ndisable=`git remote -v | grep DISABLE | wc -l`
     if [ "$tagrepo" == "0" ]; then
        if [ $ndisable -eq 0 ]; then
           echo disabling push access to firemodels
           git remote set-url --push origin DISABLE
        fi
     fi
  else
     have_central=`git remote -v | awk '{print $1}' | grep firemodels | wc -l`
     if [ $have_central -eq 0 ]; then
        echo setting up remote tracking with firemodels
        git remote add firemodels ${GITHEADER}firemodels/$repo.git
        git remote update
     fi
     if [ "$tagrepo" == "0" ]; then
        ndisable=`git remote -v | grep DISABLE | wc -l`
        if [ $ndisable -eq 0 ]; then
           echo "   disabling push access to firemodels"
           git remote set-url --push firemodels DISABLE
        else
           echo "   push access to firemodels already disabled"
        fi
     fi
  fi
done
cd $CURDIR
