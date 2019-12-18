#!/bin/bash

#---------------------------------------------
#                   CHK_REPO
#---------------------------------------------

CHK_REPO ()
{
  local repodir=$1

  if [ ! -e $repodir ]; then
     echo "***error: the repo directory $repodir does not exist."
     echo "          Aborting the make_bundle script"
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
       echo "Found branch $CURRENT_BRANCH. Aborting firebot."
       return 1
     fi
  fi
  fi
  return 0
}

#---------------------------------------------
#                   update_repo
#---------------------------------------------

UPDATE_REPO()
{
   local reponame=$1
   local branch=$2

   CD_REPO $repo/$reponame $branch || return 1

   echo Updating $branch on repo $repo/$reponame
   git remote update
   git merge origin/$branch
   have_firemodels=`git remote -v | grep firemodels | wc  -l`
   if [ $have_firemodels -gt 0 ]; then
      git merge firemodels/$branch
      need_push=`git status -uno | head -2 | grep -v nothing | wc -l`
      if [ $need_push -gt 1 ]; then
        echo "***warning: firemodels commits to $reponame repo need to be pushed to origin"
        git status -uno | head -2 | grep -v nothing
      fi
   fi
   return 0
}

curdir=`pwd`
commands=$0
DIR=$(dirname "${commands}")
cd $DIR
DIR=`pwd`
echo DIR=$DIR

cd ../..
repo=`pwd`

cd $DIR

BRANCH="-b release"

while getopts 'b:cd:fF:ghp:rS:tvVw' OPTION
do
case $OPTION  in
  b)
   bopt="-b $OPTARG"
   ;;
  c)
   copt="-c"
   ;;
  d)
   dopt="-d $OPTARG"
   ;;
  f)
   fopt="-f"
   ;;
  F)
   FOPT="-F $OPTARG"
   ;;
  g)
   gopt="-g"
   ;;
  h)
   hopt="-h"
   ;;
  p)
   popt="-p $OPTARG"
   ;;
  r)
   ropt="-r"
   ;;
  S)
   SOPT="-S $OPTARG"
   ;;
  t)
   topt="-t"
   ;;
  v)
   vopt="-v"
   ;;
  V)
   VOPT="-V"
   ;;
  w)
   wopt="-w"
   ;;
esac
done
shift $(($OPTIND-1))

# update repo 
if [ "$hopt" == "" ]; then
if [ "$vopt" == "" ]; then
  UPDATE_REPO bot master || exit 1
fi
fi

cd $DIR
./bundlebot.sh $bopt $copt $dopt $fopt $FOPT $gopt $hopt $popt $ropt $SOPT $topt $uopt $vopt $VOPT $wopt

cd $curdir

exit 0
