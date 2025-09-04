#!/bin/bash
echo Updating smokeview cache
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

CACHE_DIR=../../smokebot_cache
if [ ! -d $CACHE_DIR ]; then
  mkdir $CACHE_DIR
fi
if [ ! -d $CACHE_DIR ]; then
  echo "***error: cache directory, $CACHE_DIR, failed to be created"
  exit
fi
cd $CACHE_DIR
CACHE_DIR=`pwd`

cd ..
REPO_ROOT=`pwd`

fdsrepo=$REPO_ROOT/fds
smvrepo=$REPO_ROOT/smv
ABORT=
DIR=$fdsrepo/Build
if [ ! -d $DIR ]; then
  echo "***error: directory $DIR does not exist"
  ABORT=1
fi
DIR=$smvrepo/Verification/Visualization
if [ ! -d $DIR ]; then
  echo "***error: directory $DIR does not exist"
  ABORT=1
fi
DIR=$smvrepo/Verification/WUI
if [ ! -d $DIR ]; then
  echo "***error: directory $DIR does not exist"
  ABORT=1
fi
if [ "$ABORT" != "" ]; then
  exit
fi

rm -rf $CACHE_DIR/fds
mkdir $CACHE_DIR/fds

rm -rf $CACHE_DIR/smv
mkdir $CACHE_DIR/smv
mkdir $CACHE_DIR/smv/Verification

echo Updating $fdsrepo/Build
cp -r $fdsrepo/Build                      $CACHE_DIR/fds/.

echo Updating $smvrepo/Verification/Visualization
cp -r $smvrepo/Verification/Visualization $CACHE_DIR/smv/Verification/.

echo Updating $smvrepo/Verification/WUI
cp -r $smvrepo/Verification/WUI           $CACHE_DIR/smv/Verification/.
