#!/bin/bash
if [ "$1" == "" ]; then
  echo commit file not specified
  exit
fi
TEST_DIR=TEST_DIR
if [ ! -d TEST_DIR ]; then
  mkdir TEST_DIR
fi
CURDIR=`pwd`
cd TEST_DIR
git clean -dxf
cd $CURDIR/../../fds
FDSREPO=`pwd`
commit_file=$CURDIR/$1
cat $commit_file
COMMITS=`cat $commit_file | awk -F';' '{print $1}'`
for commit in $COMMITS; do
git checkout master
DIR=$CURDIR/$TEST_DIR/Source_$commit
cd $FDSREPO
git checkout $commit
cp -r $FDSREPO/Source $DIR
done
git checkout master
