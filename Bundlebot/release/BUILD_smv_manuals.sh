#!/bin/bash
# this script runs smokebot to build smokeview manuals using revision and tags defined in config.sh
source config.sh
OWNER="-o firemodels"
MAILTO=

#echo ***updating repos
CURDIR=`pwd`
cd ../../Scripts
echo "setting up repos"
./setup_repos.sh -A
./update_repos.sh -m
cd $CURDIR

if [ "$BUNDLE_EMAIL" != "" ]; then
  MAILTO="-m $BUNDLE_EMAIL"
fi
if [ "$BUNDLE_OWNER" != "" ]; then
  OWNER="-o $BUNDLE_OWNER"
fi
cd ../../Smokebot
./run_smokebot.sh -C -c -u -J -f -q firebot $MAILTO -x $BUNDLE_FDS_REVISION -X $BUNDLE_FDS_TAG -y $BUNDLE_SMV_REVISION -Y $BUNDLE_SMV_TAG $OWNER -r test_bundles -U -R release
