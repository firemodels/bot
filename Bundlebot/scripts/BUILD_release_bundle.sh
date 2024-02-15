#!/bin/bash
# build a release bundle using revision and tags defined in BUILD_config.sh .
# the bundle is uploaded to the github website with username firemodels and release fds
RELEASE=$1
if [ "$RELEASE" == "" ]; then
  RELEASE=fds
fi
source BUILD_config.sh
./run_bundlebot.sh -f -c -R release -F $BUNDLE_FDS_REVISION -X $BUNDLE_FDS_TAG -S $BUNDLE_SMV_REVISION -Y $BUNDLE_SMV_TAG -o firemodels -r $RELEASE
