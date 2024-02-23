#!/bin/bash
# This scripts defines revisions and tags for a bundle.
# It is run by the other BUILD scripts. 
# You do not need to run it.

# firebot pass 2/21/2024
# FDS-6.8.0-1538-g3abe090/master
# SMV-6.8.0-2075-g38047e9/master

export BUNDLE_OPTION=test
#export BUNDLE_OPTION=release

export BUNDLE_FDS_REVISION=3abe090
export BUNDLE_FDS_TAG=FDS-6.9.0
export BUNDLE_SMV_REVISION=38047e9
export BUNDLE_SMV_TAG=SMV-6.9.0

# lines below should not need to be changed

if [ "$BUNDLE_OPTION" != "release" ]; then
  BUNDLE_OPTION=test
fi
if [ "$BUNDLE_OPTION" == "test" ]; then
  GH_REPO=test_bundles
  GH_FDS_TAG=BUNDLE_TEST
  GH_SMOKEVIEW_TAG=BUNDLE_TEST
fi
if [ "$BUNDLE_OPTION" == "release" ]; then
  GH_REPO=fds
fi
export GH_REPO
export GH_FDS_TAG
export GH_SMOKEVIEW_TAG
