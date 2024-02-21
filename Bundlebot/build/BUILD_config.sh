#!/bin/bash
# This scripts defines revisions and tags for a bundle.
# It is run by the other BUILD scripts. 
# You do not need to run it.

# firebot pass 2/17/2024
# FDS-6.8.0-1523-g29bcb71/master
# SMV-6.8.0-2073-g0f8b692/master

export BUNDLE_OPTION=test
#export BUNDLE_OPTION=release
export BUNDLE_FDS_REVISION=debb46d
export BUNDLE_FDS_TAG=FDS-6.9.0
export BUNDLE_SMV_REVISION=0f8b692
export BUNDLE_SMV_TAG=SMV-6.9.0


# lines below should not need to be changed

if [ "BUNDLE_OPTION" == "nightly" ]; then
  GH_REPO=nightly_bundles
  valid=1
fi
if [ "BUNDLE_OPTION" == "test" ]; then
  GH_REPO=test_bundles
  valid=1
fi
if [ "BUNDLE_OPTION" == "release" ]; then
  GH_REPO=fds
  valid=1
fi
if [ "$valid" == "" ]; then
  GH_REPO=test_bundles
  option=test
fi
export GH_REPO
