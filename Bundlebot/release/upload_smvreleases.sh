#!/bin/bash
TEST=
if [ "$TEST" == "" ]; then
  SMVTAG=SMV-6.10.6
  OWNER=firemodels
  REPO=smv
else
  SMVTAG=SMOKEVIEW_TEST
  OWNER=gforney
  REPO=test_bundles
fi
CURDIR=`pwd`
cd smvbundles
FROM_DIR=`pwd`

for file in *.sh *.exe; do

  FROM_FILE=$file
  echo uploading $FROM_FILE to github
  gh release upload $SMVTAG $FROM_DIR/$FROM_FILE  -R github.com/$OWNER/$REPO --clobber
done
