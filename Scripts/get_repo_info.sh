#!/bin/bash
repopath=$1

repo=`basename $repopath`
cd $repopath
HASH=`git rev-parse --short HEAD`
TIMESTAMP=`git show -s --format=%ct $SHORTHASH`
REVDATE=`date -d "@$TIMESTAMP" `
echo $repo repo with hash $HASH commited on ${REVDATE}

