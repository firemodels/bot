#!/bin/bash
echo Updating fds cache
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

CACHE_DIR=../../firebot_cache
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
ABORT=
DIR=$fdsrepo/Verification/
if [ ! -d $DIR ]; then
  echo "***error: directory $DIR does not exist"
  ABORT=1
fi
if [ "$ABORT" != "" ]; then
  exit
fi
echo Updating $fdsrepo/Verification/
rm -rf $CACHE_DIR/Verification
cp -r $fdsrepo/Verification $CACHE_DIR/.
