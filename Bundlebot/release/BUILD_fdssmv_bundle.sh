#!/bin/bash
# build a release bundle using revision and tags defined in config.sh .
source config.sh
if [ "$GH_REPO" != "" ]; then
  GHREPO="-r $GH_REPO"
fi

echo ***updating repos
CURDIR=`pwd`
cd ../../Scripts
./update_repos.sh -m
cd $CURDIR

cd ../nightly
./run_bundlebot.sh -f -c -R release -F $BUNDLE_FDS_REVISION -X $BUNDLE_FDS_TAG -S $BUNDLE_SMV_REVISION -Y $BUNDLE_SMV_TAG -o firemodels $GHREPO
cd $CURDIR

TITLE="Bundle Test - $BUNDLE_FDS_TAG/$BUNDLE_FDS_REVISION - $BUNDLE_SMV_TAG/$BUNDLE_SMV_REVISION"
gh release edit $GH_FDS_TAG  -t "$TITLE" -R github.com/$GH_OWNER/$GH_REPO
