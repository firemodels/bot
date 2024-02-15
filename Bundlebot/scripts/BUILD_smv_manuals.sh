#!/bin/bash
# this script runs smokebot to build smokeview manuals using revision and tags defined in BUILD_config.sh
source BUILD_config.sh
MAILTO=
if [ "$BUNDLE_EMAIL" != "" ]; then
  MAILTO="-m $BUNDLE_EMAIL"
fi
cd ../../Smokebot
./run_smokebot.sh -c -u -J -q smokebot $MAILTO -x $BUNDLE_FDS_REVISION -X $BUNDLE_FDS_TAG -y $BUNDLE_SMV_REVISION -Y $BUNDLE_SMV_TAG -R release
