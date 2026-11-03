#!/bin/bash
branch=$1
repo=$2

if [[ "$branch" == "" ]] && [[ "$repo" == "" ]]; then
  echo "Usage: newbranch.sh branch repo"
  echo " create a branch in repo repo."
  echo ""
  echo " branch - branch to be created"
  echo " repo   - repo branch is created in (default: smv)"
  exit
fi

CURDIR=`pwd`

cd ../..
GITROOT=`pwd`

cd $CURDIR

if [ "$repo" == "" ]; then
  repo=smv
fi
repodir=$GITROOT/$repo
if [ ! -d $repodir ]; then
  echo "***error: repo $repodir does not exist"
  exit 1
fi
if [ "$branch" == "" ]; then
  echo "***error: branch not specified"
  exit 1
fi

echo "Do you wish to create the branch: $branch in repo: $repo "
echo "Press any key to continue or <CTRL> c to abort."
read val

cd $repodir
git checkout -b $branch firemodels/master
git push -u origin $branch


