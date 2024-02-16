#!/bin/bash
# this script runs firebot to build fds manuals using revision and tags defined in BUILD_config.sh
source BUILD_config.sh
MAILTO=
GHOWNER=
if [ "$BUNDLE_EMAIL" != "" ]; then
  MAILTO="-m $BUNDLE_EMAIL"
fi
if [ "$GH_OWNER" != "" ]; then
  GHOWNER="-o $GH_OWNER"
fi
if [ "$GH_REPO" != "" ]; then
  GHREPO="-r $GH_REPO"
fi
cd ../../Firebot
./run_firebot.sh -c -J -q firebot $MAILTO -x $BUNDLE_FDS_REVISION -X $BUNDLE_FDS_TAG  -y $BUNDLE_SMV_REVISION -Y $BUNDLE_SMV_TAG -U $GHREPO $GHOWNER -R release 
