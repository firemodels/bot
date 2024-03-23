#!/bin/bash
FROMFILE=$1
TAG=$2

rm -f $FROMFILE
gh release download $TAG -p $FROMFILE -R github.com/$GH_OWNER/$GH_REPO --clobber
if [ -e $FROMFILE ]; then
  cat $FROMFILE
else
  echo ""
fi
