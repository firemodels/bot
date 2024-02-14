#!/bin/bash
source BUILD_revtag.sh
./run_smokebot.sh -c -u -J -q smokebot -m gforney@gmail.com  -x $BUNDLE_FDS_REVISION -X $BUNDLE_FDS_TAG -y $BUNDLE_SMV_REVISION -Y $BUNDLE_SMV_TAG -R release -M -U -w smokebot/clone
