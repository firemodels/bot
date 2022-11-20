#!/bin/bash
repopath=$1

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
  REVDATE=`date -d "@$TIMESTAMP" `
else
  REVDATE=`date -r "$TIMESTAMP" `
fi
echo $repo repo hash: $HASH, commit date: ${REVDATE}

