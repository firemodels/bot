#!/bin/bash
fds_hash=$1
smv_hash=$2
release=$3
if [ "$release" == "" ]; then
  branch_name=nightly
else
  branch_name=release
fi

CURDIR=`pwd`
cd ../../..
REPOROOT=`pwd`

cd $REPOROOT/bot/Scripts
./setup_repos.sh -T

cd $REPOROOT/fds
git checkout -b $branch_name $fds_hash
git describe --abbrev=7 --dirty --long

cd $REPOROOT/smv
git checkout -b $branch_name $smv_hash
git describe --abbrev=7 --dirty --long

cd $CURDIR

