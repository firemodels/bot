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
COMMITS=`cat $commit_file | awk -F';' '{print $1}'`
count=1
for commit in $COMMITS; do
  cd $FDSREPO
  git checkout master >& /dev/null
  COMMITDIR=$TESTDIR/${count}_$commit
  mkdir $COMMITDIR
  count=$((count+1))
  cd $FDSREPO
  git checkout $commit >& /dev/null
  cp -r $FDSREPO/Source $COMMITDIR/Source
  cp -r $FDSREPO/Build  $COMMITDIR/Build
  rm $COMMITDIR/Build/impi_intel_linux_64/*.o
  rm $COMMITDIR/Build/impi_intel_linux_64/*.mod
  rm $COMMITDIR/Build/impi_intel_linux_64/fds*
  cd $CURDIR
  echo building fds using revision $commit
  ./qbuild.sh -j fds$commit -d $COMMITDIR/Build/impi_intel_linux_64 > $CURDIR/script.xxx
done
echo $FDSREPO
git checkout master >& /dev/null
