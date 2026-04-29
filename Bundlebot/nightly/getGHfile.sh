#!/bin/bash
FROMFILE=$1

rm -f $FROMFILE
gh release download FDS_TEST -p $FROMFILE -R github.com/firemodels/test_bundles --clobber
if [ -e $FROMFILE ]; then
  cat $FROMFILE
else
  echo ""
fi
