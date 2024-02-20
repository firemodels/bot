#!/bin/bash
option=$1
# this script sets which release to upload bundles too

valid=
# this option is not used yet
if [ "$option" == "nightly" ]; then
  GH_REPO=nightly_bundles
  valid=1
fi
if [ "$option" == "test" ]; then
  GH_REPO=test_bundles
  valid=1
fi
if [ "$option" == "release" ]; then
  GH_REPO=fds
  valid=1
fi
if [ "$valid" == "" ]; then
  GH_REPO=test_bundles
  option=test
fi
export GH_REPO
