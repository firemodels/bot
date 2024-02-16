#!/bin/bash
# this script runs smokebot to build smokeview manuals using revision and tags defined in BUILD_config.sh
source BUILD_config.sh
MAILTO=
GHOWNER=
GHREPO=
if [ "$BUNDLE_EMAIL" != "" ]; then
  MAILTO="-m $BUNDLE_EMAIL"
fi
if [ "$GH_OWNER" != "" ]; then
  GHOWNER="-o $GH_OWNER"
fi
if [ "$GH_REPO" != "" ]; then
  GHREPO="-r $GH_REPO"
fi
cd ../../Smokebot
./run_smokebot.sh -c -u -J -f -q smokebot $MAILTO -x $BUNDLE_FDS_REVISION -X $BUNDLE_FDS_TAG -y $BUNDLE_SMV_REVISION -Y $BUNDLE_SMV_TAG $GHOWNER $GHREPO -U -R release
