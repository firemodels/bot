#!/bin/bash
FROM_DIR=$1
FROM_FILE=$2
SCRIPTDIR=$3

OWNER=`whoami`

CURDIR=`pwd`

if [ ! -e $HOME/$FROM_DIR/$FROM_FILE ] ; then
  echo "***error: $FROM_FILE does not exist in $HOME/$FROM_DIR"
  exit
fi

echo uploading $FROM_FILE to github
gh release upload SMOKEVIEW_TEST $HOME/$FROM_DIR/$FROM_FILE  -R github.com/$OWNER/test_bundles --clobber
if [ "`uname`" == "Darwin" ] ; then
  platform=osx
else
  platform=linux
fi
if [ "$platform" == "linux" ]; then
  cd $HOME/$SCRIPTDIR/../../../smv
  SMV_SHORT_HASH=`git rev-parse --short HEAD`
  cd $HOME/$SCRIPTDIR
  ./setreleasetitle.sh smv $SMV_SHORT_HASH $OWNER
fi

