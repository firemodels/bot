#!/bin/bash
smv_hash=$1
release=$2
if [ "$release" == "" ]; then
  branch_name=nightly
else
  branch_name=release
fi

CURDIR=`pwd`
cd ../../../..
REPOROOT=`pwd`

cd $REPOROOT/bot/Scripts
./setup_repos.sh -U

cd $REPOROOT/smv

git checkout -b $branch_name $smv_hash

git describe --abbrev=7 --dirty --long
git branch -a

cd $CURDIR

