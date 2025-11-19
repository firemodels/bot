#!/bin/bash
# build a release bundle using revision and tags defined in config.sh .
source config.sh
export DISABLEPUSH=1
export BUILDING_release=1

# FDS-6.9.0-96-g889da6ae0
#export BUNDLE_FDS_HASH=889da6ae0
#export BUNDLE_FDS_TAG=FDS-6.9.1test

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
./BUILD_fdssmv_nightly.sh -b -c -f -R release -o $OWNER -r test_bundles

cd $CURDIR
TITLE="Bundle Test - $BUNDLE_FDS_TAG/$BUNDLE_FDS_HASH - $BUNDLE_SMV_TAG/$BUNDLE_SMV_HASH"
gh release edit FDS_TEST  -t "$TITLE" -R github.com/$OWNER/test_bundles
