#!/bin/bash
if [ "$1" == "" ]; then
  echo commit file not specified
  exit
fi
if [ ! -d TESTDIR ]; then
  mkdir TESTDIR
fi
CURDIR=`pwd`

cd TESTDIR
TESTDIR=`pwd`
git clean -dxf
cd $CURDIR/../../fds
FDSREPO=`pwd`
commit_file=$CURDIR/$1
cat $commit_file
COMMITS=`cat $commit_file | awk -F';' '{print $1}'`
count=1
for commit in $COMMITS; do
git checkout master
COMMITDIR=$TESTDIR/${count}_$commit
count=$((count+1))
mkdir $COMMITDIR
cd $FDSREPO
git checkout $commit
cp -r $FDSREPO/Source $COMMITDIR/Source
cp -r $FDSREPO/Build $COMMITDIR/Build
cd $COMMITDIR/Build/impi_intel_linux_64
./make_fds.sh >& /dev/null &
done
git checkout master
