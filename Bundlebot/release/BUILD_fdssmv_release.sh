#!/bin/bash
# build a release bundle using revision and tags defined in config.sh .
source config.sh
export DISABLEPUSH=1
export BUILDING_release=1

# FDS-6.9.0-96-g889da6ae0
#export BUNDLE_FDS_REVISION=889da6ae0
#export BUNDLE_FDS_TAG=FDS-6.9.1test

OWNER=`whoami`

CURDIR=`pwd`

echo ***cleaning bot repo
cd ../..
git clean -dxf  >& /dev/null

echo ***cloning repos
cd $CURDIR/../../Scripts
./setup_repos.sh -D -A
./update_repos.sh -w
./update_bottag.sh

cd $CURDIR/../nightly
./BUILD_fdssmv_nightly.sh -c -f -R release -F $BUNDLE_FDS_REVISION -X $BUNDLE_FDS_TAG -S $BUNDLE_SMV_REVISION -Y $BUNDLE_SMV_TAG -o $OWNER -r test_bundles

cd $CURDIR
TITLE="Bundle Test - $BUNDLE_FDS_TAG/$BUNDLE_FDS_REVISION - $BUNDLE_SMV_TAG/$BUNDLE_SMV_REVISION"
gh release edit FDS_TEST  -t "$TITLE" -R github.com/$OWNER/test_bundles
