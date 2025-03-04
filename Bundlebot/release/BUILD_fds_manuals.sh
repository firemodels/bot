#!/bin/bash
# this script runs firebot to build fds manuals using revision and tags defined in config.sh
source config.sh
export DISABLEPUSH=1
MAILTO=
OWNER="-o firemodels"

CURDIR=`pwd`
cd ../../Scripts
echo ***setting up repos
./setup_repos.sh -A
./update_repos.sh -w
cd $CURDIR

if [ "$BUNDLE_EMAIL" != "" ]; then
  MAILTO="-m $BUNDLE_EMAIL"
fi
if [ "$BUNDLE_OWNER" != "" ]; then
  OWNER="-o $BUNDLE_OWNER"
fi
cd ../../Firebot
./run_firebot.sh -C -f -c -J -q firebot $MAILTO -U -r test_bundles $OWNER -R release -z
