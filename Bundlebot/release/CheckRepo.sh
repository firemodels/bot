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
REVISION=`git rev-parse --short HEAD`

echo "repo   $REPOVERSION"
echo "config $CONFIGTAG"
echo "repo   $REVISION"
echo "config $CONFIGVERSION"
echo ""
}

CURDIR=`pwd`
gitroot=$CURDIR/../../..
cd $gitroot
gitroot=`pwd`
cd $CURDIR

GETREV cad $BUNDLE_CAD_REVISION $BUNDLE_CAD_TAG
GETREV exp $BUNDLE_EXP_REVISION $BUNDLE_EXP_TAG
GETREV fds $BUNDLE_FDS_REVISION $BUNDLE_FDS_TAG
GETREV fig $BUNDLE_FIG_REVISION $BUNDLE_FIG_TAG
GETREV out $BUNDLE_OUT_REVISION $BUNDLE_OUT_TAG
GETREV smv $BUNDLE_SMV_REVISION $BUNDLE_SMV_TAG
