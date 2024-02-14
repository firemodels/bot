#!/bin/bash
source BUILD_config.sh
./run_firebot.sh -c -J -q firebot -m $BUNDLE_EMAIL -x $BUNDLE_FDS_REVISION -X $BUNDLE_FDS_TAG  -y $BUNDLE_SMV_REVISION -Y $BUNDLE_SMV_TAG -r test7_bundles -U -o $BUNDLE_USER -R release 
