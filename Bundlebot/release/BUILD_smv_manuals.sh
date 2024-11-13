#!/bin/bash
# this script runs smokebot to build smokeview manuals using revision and tags defined in config.sh
source config.sh

echo ***updating repos
CURDIR=`pwd`
cd ../../Scripts
./update_repos.sh -m
cd $CURDIR

MAILTO=
if [ "$BUNDLE_EMAIL" != "" ]; then
  MAILTO="-m $BUNDLE_EMAIL"
fi
cd ../../Smokebot
./run_smokebot.sh -C -c -u -J -f -q firebotbot $MAILTO -x $BUNDLE_FDS_REVISION -X $BUNDLE_FDS_TAG -y $BUNDLE_SMV_REVISION -Y $BUNDLE_SMV_TAG -o firemodels -r test_bundles -U -R release
