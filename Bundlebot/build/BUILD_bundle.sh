#!/bin/bash
# build a release bundle using revision and tags defined in BUILD_config.sh .
# the bundle is uploaded to the github website with username firemodels and release fds
option=$1
if [ "$option" != "release" ]; then
  option=test
fi
source BUILD_config.sh $option
if [ "$GH_REPO" != "" ]; then
  GHREPO="-r GH_REPO"
fi
cd ../scripts
./run_bundlebot.sh -f -c -R release -F $BUNDLE_FDS_REVISION -X $BUNDLE_FDS_TAG -S $BUNDLE_SMV_REVISION -Y $BUNDLE_SMV_TAG -o firemodels $GHREPO
