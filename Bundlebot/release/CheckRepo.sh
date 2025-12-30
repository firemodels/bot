#!/bin/bash
source config.sh

GETREV ()
{
repo=$1
CONFIGVERSION=$2
CONFIGTAG=$3
cd $gitroot/$repo
REPO=$(echo "$repo" | awk '{print toupper($0)}')
REPOVERSION=`git describe --dirty --long`
HASH=`git rev-parse --short HEAD`

echo "repo   $REPOVERSION"
echo "config $CONFIGTAG"
echo "repo   $HASH"
echo "config $CONFIGVERSION"
echo ""
}

CURDIR=`pwd`
gitroot=$CURDIR/../../..
cd $gitroot
gitroot=`pwd`
cd $CURDIR

GETREV cad $BUNDLE_CAD_HASH $BUNDLE_CAD_TAG
GETREV exp $BUNDLE_EXP_HASH $BUNDLE_EXP_TAG
GETREV fds $BUNDLE_FDS_HASH $BUNDLE_FDS_TAG
GETREV fig $BUNDLE_FIG_HASH $BUNDLE_FIG_TAG
GETREV out $BUNDLE_OUT_HASH $BUNDLE_OUT_TAG
GETREV smv $BUNDLE_SMV_HASH $BUNDLE_SMV_TAG
