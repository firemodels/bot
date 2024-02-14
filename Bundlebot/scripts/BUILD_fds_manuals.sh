#!/bin/bash
source BUILD_revtag.sh
./run_firebot.sh -c -J -q firebot -m gforney@gmail.com -x $BUNDLE_FDS_REVISION -X $BUNDLE_FDS_TAG  -y $BUNDLE_SMV_REVISION -Y $BUNDLE_SMV_TAG -r test7_bundles -U -o gforney -R release 
