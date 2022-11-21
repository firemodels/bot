#!/bin/bash
repopath=$1
option=$2

if [ "`uname`" == "Darwin" ]; then
  platform="osx"
else
  platform="linux"
fi

repo=`basename $repopath`
cd $repopath
HASH=`git rev-parse --short HEAD`
TIMESTAMP=`git show -s --format=%ct $SHORTHASH`
if [ "$platform" == "linux" ]; then
  if [ "$option" == "" ]; then
    REVDATE=`date -d "@$TIMESTAMP" `
  else
    REVDATE=`date +'%Y%b%d' -d "@$TIMESTAMP"`
  fi
else
  if [ "$option" == "" ]; then
    REVDATE=`date -r "$TIMESTAMP" `
  else
    REVDATE=`date +'%Y%b%d' -r "$TIMESTAMP"`
  fi
fi
if [ "$option" == "" ]; then
  echo $repo repo hash: $HASH, commit date: ${REVDATE}
else
  echo $REVDATE
fi

