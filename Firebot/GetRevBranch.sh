#!/bin/bash
repodir=$1

cd ../..
if [ ! -d $repodir ]; then
  echo unknown
  exit
fi
cd $repodir
rev=`git describe --dirty --long`
branch=`git branch --show-current`
echo $rev/$branch
