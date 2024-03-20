#!/bin/bash
repo=$1
branch=$2

if [ $# -ne 2 ]; then
  echo ***error: found $# arguments, was expecting 2
  echo usage:
  echo ./newbranch repo branch
  exit
fi

set CURDIR=`pwd`

cd ../..
GITROOT=`pwd`

cd $CURDIR

repodir=$GITROOT/$repo
if [ ! -d $repodir ]; then
  echo ***error: repo $repodir does not exist
  exit
fi

echo "Do you wish to create the branch: $branch in repo: $repo ?"
echo "Press any key to continue or <CTRL> c to abort."
read val

cd $repodir
git checkout -b $branch firemodels/master
git push -u origin $branch


