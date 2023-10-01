#!/bin/bash

CURDIR=`pwd`
if [ "$GH_FDS_TAG" == "" ]; then
  echo "***error: GH_FDS_TAG variable not defined"
  exit 1
fi

cd ../../fds/Manuals
MANDIR=`pwd`

DIR=$HOME/.firebot
if [ ! -d $DIR ]; then
  mkdir $DIR
fi

rm -f $DIR/FDS_Summary.tar
tar cvf $DIR/FDS_Summary.tar FDS_Summary >& /dev/null
echo ***Uploading FDS_Summary.tar
gh release upload $GH_FDS_TAG $DIR/FDS_Summary.tar -R github.com/$GH_OWNER/$GH_REPO --clobber

cd $CURDIR
