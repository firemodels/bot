#!/bin/bash
# build a release bundle using revision and tags defined in BUILD_config.sh .
source BUILD_config.sh
if [ "$GH_REPO" != "" ]; then
  GHREPO="-r $GH_REPO"
fi

echo ***updating repos
CURDIR=`pwd`
cd ../../Scripts
./update_repos.sh
cd $CURDIR

cd ../scripts
./run_bundlebot.sh -f -c -R release -F $BUNDLE_FDS_REVISION -X $BUNDLE_FDS_TAG -S $BUNDLE_SMV_REVISION -Y $BUNDLE_SMV_TAG -o firemodels $GHREPO
