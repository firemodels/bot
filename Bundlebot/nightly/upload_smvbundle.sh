#!/bin/bash
FROM_DIR=$1
FROM_FILE=$2
SCRIPTDIR=$3
RELEASEBRANCH=$4
GH_OWNER_ARG=$5
GH_REPO_ARG=$6

CURDIR=`pwd`

if [ ! -e $HOME/$FROM_DIR/$FROM_FILE ] ; then
  echo "***error: $FROM_FILE does not exist in $HOME/$FROM_DIR"
  exit
fi

echo uploading $FROM_FILE to github
gh release upload $RELEASEBRANCH $HOME/$FROM_DIR/$FROM_FILE  -R github.com/$GH_OWNER_ARG/$GH_REPO_ARG --clobber
if [ "`uname`" == "Darwin" ] ; then
  platform=osx
else
  platform=linux
fi
if [ "$platform" == "linux" ]; then
  cd $HOME/$SCRIPTDIR/../../../smv
  SMV_SHORT_HASH=`git rev-parse --short HEAD`
  cd $HOME/$SCRIPTDIR
  ./setreleasetitle.sh smv $SMV_SHORT_HASH $GH_OWNER_ARG $GH_REPO_ARG
fi

