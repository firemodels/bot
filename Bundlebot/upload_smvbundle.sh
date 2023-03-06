#!/bin/bash
FROM_DIR=$1
FROM_FILE=$2
PLATFORM=$3
EXT=$4
RELEASE_BUNDLE=$5

if [ ! -e $HOME/$FROM_DIR/$FROM_FILE ] ; then
  echo "***error: $FROM_FILE does not exist in $HOME/$FROM_DIR"
  exit
fi

if [ "$RELEASE_BUNDLE" != "" ]; then
  cd $HOME/$RELEASE_BUNDLE
  echo uploading $FROM_FILE to github
  gh release upload TEST_BUNDLES $HOME/$FROM_DIR/$FROM_FILE  --clobber
fi

