#!/bin/bash
FIREBOT_HOST=$1
MAILTO=$2
FDS_RELEASE=$3
SMV_RELEASE=$4

FORCE=
#FORCE=-f

if [ "$FIREBOT_HOST" == "" ]; then
  exit 1
fi
if [ "$MAILTO" == "" ]; then
  exit 1
fi

JOPT="-J"
if [ "`uname`" == "Darwin" ] ; then
  JOPT=
fi

# both or neither RELEASE options must be set
BRANCH="test"
if [ "$FDS_RELEASE" != "" ]; then
  if [ "$SMV_RELEASE" != "" ]; then
    FDS_RELEASE="-x $FDS_RELEASE"
    SMV_RELEASE="-y $SMV_RELEASE"
    BRANCH="release"
  fi
fi
if [ "$FDS_RELEASE" == "" ]; then
  SMV_RELEASE=""
fi
if [ "$SMV_RELEASE" == "" ]; then
  FDS_RELEASE=""
fi
FIREBOT_BRANCH="-R $BRANCH"
BUNDLE_BRANCH="-b $BRANCH"


curdir=`pwd`

cd ../Firebot
./run_firebot.sh $FORCE -c -C -B -g $FIREBOT_HOST -G \~firebot $JOPT $FDS_RELEASE $SMV_RELEASE $FIREBOT_BRANCH -T -m $MAILTO

cd $curdir
./run_bundlebot.sh $FORCE $BUNDLE_BRANCH -p $FIREBOT_HOST -w -g
