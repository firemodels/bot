#!/bin/bash
FROMFILE=$1

rm -f $FROMFILE
gh release download FDS_TEST -p $FROMFILE -R github.com/firemodels/test_bundles --clobber
if [ ! -e $FROMFILE ]; then
  echo ***error: $FROMFILE failed to download using:
  echo "         gh release download FDS_TEST -p $FROMFILE -R github.com/firemodels/test_bundles --clobber"
fi
