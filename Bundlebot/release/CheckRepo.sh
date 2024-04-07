#!/bin/bash
source config.sh

GETREV ()
{
repo=$1
cd $gitroot/$repo
REPO=$(echo "$repo" | awk '{print toupper($0)}')
REPOVERSION=`git describe --dirty --long`
REVISION=`git rev-parse --short HEAD`

echo "$REPOVERSION (repo)"
echo "$REVISION (repo)"
}

CURDIR=`pwd`
gitroot=$CURDIR/../../..
cd $gitroot
gitroot=`pwd`
cd $CURDIR

GETREV cad
echo "$BUNDLE_CAD_REVISION (config)"
echo "$BUNDLE_CAD_TAG (config)"
echo ""

GETREV exp
echo "$BUNDLE_EXP_REVISION (config)"
echo "$BUNDLE_EXP_TAG (config)"
echo ""

GETREV fds
echo "$BUNDLE_FDS_REVISION (config)"
echo "$BUNDLE_FDS_TAG (config)"
echo ""

GETREV fig
echo "$BUNDLE_FIG_REVISION (config)"
echo "$BUNDLE_FIG_TAG (config)"
echo ""

GETREV out
(echo "$BUNDLE_OUT_REVISION config)"
echo "$BUNDLE_OUT_TAG (config)"
echo ""

GETREV smv
echo "$BUNDLE_SMV_REVISION (config)"
echo "$BUNDLE_SMV_TAG (config)"
echo ""
