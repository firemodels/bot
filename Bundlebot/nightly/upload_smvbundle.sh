#!/bin/bash
FROM_DIR=$1
FROM_FILE=$2
SCRIPTDIR=$3
OWNER=$4

CURDIR=`pwd`

if [ ! -e $FROM_DIR/$FROM_FILE ] ; then
  echo "***error: $FROM_FILE does not exist in $FROM_DIR"
  exit
fi

echo uploading $FROM_FILE to github
gh release upload SMOKEVIEW_TEST $FROM_DIR/$FROM_FILE  -R github.com/$OWNER/test_bundles --clobber
if [ "`uname`" != "Darwin" ] ; then
  cd $HOME/$SCRIPTDIR/../../../smv
  SMV_SHORT_HASH=`git rev-parse --short HEAD`
  cd $HOME/$SCRIPTDIR
  ./setreleasetitle.sh smv $SMV_SHORT_HASH $OWNER
fi

