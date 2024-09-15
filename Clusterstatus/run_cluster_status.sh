#!/bin/bash

#---------------------------------------------
#                   CHK_REPO
#---------------------------------------------

CHK_REPO ()
{
  local repodir=$1

  if [ ! -e $repodir ]; then
     echo "***error: the repo directory $repodir does not exist."
     echo "          Aborting smokebot."
     return 1
  fi
  return 0
}

#---------------------------------------------
#                   CD_REPO
#---------------------------------------------

CD_REPO ()
{
  local repodir=$1
  local branch=$2

  CHK_REPO $repodir || return 1

  cd $repodir
  if [ "$branch" != "current" ]; then
    if [ "$branch" != "" ]; then
      CURRENT_BRANCH=`git rev-parse --abbrev-ref HEAD`
      if [ "$CURRENT_BRANCH" != "$branch" ]; then
        echo "***error: was expecting branch $branch in repo $repodir."
        echo "Found branch $CURRENT_BRANCH. Aborting smokebot."
        return 1
      fi
    fi
  fi
  return 0
}

ABORT=
if [ "$CB_BASE" == "" ]; then
  ABORT=1
  echo "***error: The environment variable CB_BASE not defined"
fi  
if [ "$CB_BEG" == "" ]; then
  ABORT=1
  echo "***error: The environment variable CB_BEG not defined"
fi  
if [ "$CB_END" == "" ]; then
  ABORT=1
  echo "***error: The environment variable CB_END not defined"
fi
if [ "$ABORT" != "" ]; then
  exit
fi

CURDIR=`pwd`
cd ../..
repo=`pwd`
cd $CURDIR
CD_REPO $repo/bot/Clusterstatus master || exit 1
    
git fetch origin        &> /dev/null
git merge origin/master &> /dev/null

./cluster_status.sh none $CB_BASE $CB_BEG $CB_END
