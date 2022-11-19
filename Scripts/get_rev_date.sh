#!/bin/bash
repo=$1
cd $repo
HASH=`git rev-parse --short HEAD`
TIMESTAMP=`git show -s --format=%ct $SHORTHASH`
REVDATE=`date -d "@$TIMESTAMP" | awk '{print $6$2$3}'`
echo ${REVDATE}_$HASH

