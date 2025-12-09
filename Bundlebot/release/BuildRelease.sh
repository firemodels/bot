#!/bin/bash
# build a release bundle using revision and tags defined in config.sh .
source config.sh
export DISABLEPUSH=1
export BUILDING_release=1

# for testing build bundle with a specified hash and tag
#export BUNDLE_FDS_HASH=889da6ae0
#export BUNDLE_FDS_TAG=FDS-6.9.1test
#export BUNDLE_SMV_HASH=xxxxx
#export BUNDLE_SMV_TAG=SMV-6.9.1test

OWNER=`whoami`

CURDIR=`pwd`

echo ***cleaning bot repo
cd $CURDIR/../../Firebot
git clean -dxf  >& /dev/null
cd $CURDIR/output
git clean -dxf  >& /dev/null
cd $CURDIR/../nightly
git clean -dxf  >& /dev/null

cd $CURDIR/../nightly
./BuildNightly.sh -c -f -R release -o $OWNER -r test_bundles

cd $CURDIR
TITLE="Bundle Test - $BUNDLE_FDS_TAG/$BUNDLE_FDS_HASH - $BUNDLE_SMV_TAG/$BUNDLE_SMV_HASH"
gh release edit FDS_TEST  -t "$TITLE" -R github.com/$OWNER/test_bundles
